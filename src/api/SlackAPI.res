open Express

type challenge = string

type event = {
  text: string,
  ts: option<string>,
  user: string,
  team: string,
  channel: string,
  botId: option<string>,
  threadTs: option<string>,
  _type: string,
}

type eventPayload = {
  teamId: string,
  apiAppId: string,
  _type: string,
  eventId: string,
  eventTime: int,
  isExtSharedChannel: bool,
  eventContext: string,
  event: event,
}

type requests =
  | Challenge(string)
  | Event(eventPayload)
  | Invalid

let eventDecoder = json => {
  open Json.Decode
  {
    text: field("text", string, json),
    ts: field("ts", optional(string), json),
    user: field("user", string, json),
    team: field("team", string, json),
    channel: field("channel", string, json),
    botId: optional(field("bot_id", string), json),
    threadTs: optional(field("thread_ts", string), json),
    _type: field("type", string, json),
  }
}

let eventPayloadDecoder = json => {
  open Json.Decode
  {
    teamId: field("team_id", string, json),
    apiAppId: field("api_app_id", string, json),
    _type: field("type", string, json),
    eventId: field("event_id", string, json),
    eventTime: field("event_time", int, json),
    isExtSharedChannel: field("is_ext_shared_channel", bool, json),
    eventContext: field("event_context", string, json),
    event: field("event", eventDecoder, json),
  }
}

let isValidPayload = json => {
  open Json.Decode
  switch field("token", string, json) {
  | token => token === Settings.slackVerificationToken
  | exception DecodeError(_) => false
  }
}

let getPayload = json => {
  open Json.Decode
  isValidPayload(json)
    ? switch field("challenge", string, json) {
      | value => Challenge(value)
      | exception DecodeError(_) => Event(eventPayloadDecoder(json))
      }
    : Invalid
}

let getIntent = payload => {
  let testFuncs = list{
    (
      Intent.News,
      payload => payload.event._type === "app_mention" && Core.News.isNews(payload.event.text),
    ),
    (
      Intent.Greeting,
      payload =>
        Core.Greeter.isGreeting(payload.event.botId, payload.event.threadTs, payload.event.text) &&
        Core.News.isNews(payload.event.text) === false,
    ),
  }
  let isValid = item => {
    let (_, testFunc) = item
    testFunc(payload) === true
  }
  let intent = switch List.find(isValid, testFuncs) {
  | exception Not_found => Unknown
  | (intent, _) => intent
  }
  Js.log(`Received ${intent |> Intent.toString} intent`)
  intent
}

let sendError = payload => {
  let client = Slack.make(Slack.token)
  let args = {
    let args = list{("channel", payload.event.channel), ("token", Slack.token)}
    switch payload.event.ts {
    | Some(ts) => list{("thread_ts", ts), ...args}
    | None => args
    }
  }
  let blocks = [
    Slack.Block.Image("https://media.giphy.com/media/oe33xf3B50fsc/giphy.gif", "explosion"),
    Slack.Block.Section(Intent.error(None)),
  ]
  let _ = Slack.sendMessage(
    client,
    List.concat(list{
      args,
      list{
        ("text", "Une erreur est survenue"),
        (
          "blocks",
          Array.map(block => block |> Slack.Block.build, blocks)
          |> Js.Json.array
          |> Js.Json.stringify,
        ),
      },
    }) |> Js.Dict.fromList,
  )
}

let sendGreeting = payload => {
  let answer = Core.Greeter.greet(payload.event.user)
  let args =
    [
      ("channel", payload.event.channel),
      ("text", answer),
      ("token", Slack.token),
    ] |> Js.Dict.fromArray

  let client = Slack.make(Slack.token)
  Slack.sendMessage(client, args)
}

let sendNews = payload => {
  open NewsAPI
  open Js.Promise
  let api = NewsAPI.make(Settings.newsAPIToken)
  let client = Slack.make(Slack.token)
  let args = {
    let args = list{("channel", payload.event.channel), ("token", Slack.token)}
    switch payload.event.ts {
    | Some(ts) => list{("thread_ts", ts), ...args}
    | None => args
    }
  }

  topHeadlines(api, ()) |> then_(result => {
    switch result {
    | Ok(articles) => {
        let blocks = Array.map((article: article) => {
          let title = "<" ++ article.url ++ "|" ++ article.title ++ ">"
          Slack.Block.SectionWithAccessory(
            title,
            article.imageUrl,
            article.title,
          ) |> Slack.Block.build
        }, articles) |> Js.Json.array
        Slack.sendMessage(
          client,
          List.concat(list{
            args,
            list{
              (
                "text",
                `Oh non ! Je n'ai pas réussi. Je crois que j'ai besoin qu'on me ressere les boulons ...`,
              ),
              ("blocks", blocks |> Js.Json.stringify),
            },
          }) |> Js.Dict.fromList,
        )
      }
    | Error(_) => sendError(payload) |> resolve
    }
  })
}

let sendAffirmative = (payload, intent) => {
  let text = Intent.affirmative(intent)
  let client = Slack.make(Slack.token)
  let args =
    [
      ("channel", payload.event.channel),
      ("text", text),
      ("token", Slack.token),
    ] |> Js.Dict.fromArray
  switch payload.event.ts {
  | Some(ts) => Js.Dict.set(args, "thread_ts", ts)
  | None => ()
  }
  Slack.sendMessage(client, args)
}

let processEventPayload = payload => {
  let intent = getIntent(payload)
  switch intent {
  | Intent.Unknown => ()
  | Intent.News => {
      let _ = sendAffirmative(payload, intent) |> Js.Promise.then_(_ => {
        Js.Promise.resolve(sendNews(payload))
      })
    }
  | Intent.Greeting =>
    let _ = sendGreeting(payload)
  }
}

let middleware = Middleware.from((_, req, res) => {
  let body = Request.bodyJSON(req)
  switch body {
  | Some(json) =>
    switch getPayload(json) {
    | Invalid => Response.sendStatus(Response.StatusCode.Forbidden, res)
    | Challenge(challengeValue) => {
        Js.log("Challenge accepted !")
        Response.sendString(challengeValue, res)
      }
    | Event(payload) =>
      processEventPayload(payload)
      Response.sendStatus(Response.StatusCode.Ok, res)
    }
  | None => Response.sendString("Invalid payload", res)
  }
})

let init = prefix => {
  API.registerMiddleware(~path=prefix ++ "/", Request.Post, middleware)
}
