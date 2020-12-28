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
    botId: optional(field("bot_id", Json.Decode.string), json),
    threadTs: optional(field("thread_ts", Json.Decode.string), json),
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

let processEventRequest = payload => {
  let answer = Core.Greeter.greet(payload.event.user)
  let args: Slack.messageArgs = {
    channel: payload.event.channel,
    thread_ts: payload.event.ts,
    text: answer,
    token: Slack.token,
  }
  let client = Slack.make(Slack.token)
  Slack.sendMessage(client, args)
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
      Js.log(payload)
      switch Core.Greeter.isGreeting(
        payload.event.botId,
        payload.event.threadTs,
        payload.event.text |> Js.String.toLowerCase,
      ) {
      | true =>
        Js.log("Greeting request received")
        let _ =
          processEventRequest(payload) |> Js.Promise.then_(_ =>
            Js.log("Greeting sent") |> Js.Promise.resolve
          )
      | false => Js.log("not a greeting request")
      }
      Response.sendStatus(Response.StatusCode.Ok, res)
    }
  | None => Response.sendString("Invalid payload", res)
  }
})

let init = prefix => {
  API.registerMiddleware(~path=prefix ++ "/", Request.Post, middleware)
}
