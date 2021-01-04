open Express

let client = Slack.make(Slack.token)

let getMessage = (payload: Decoder.eventPayload) => {
  let message: Message.message = {
    text: payload.event.text,
    id: payload.eventId,
    time: payload.eventTime,
    userId: payload.event.user,
    channel: payload.event.channel,
    threadId: payload.event.ts,
    botId: payload.authorizations[0].userId,
    _type: payload.event._type |> Message.Type.fromString,
  }
  message
}

let sendError = (message: Message.message) => {
  let args = switch message.threadId {
  | Some(ts) => list{("channel", message.channel), ("token", Slack.token), ("thread_ts", ts)}
  | None => list{("channel", message.channel), ("token", Slack.token)}
  }
  let blocks =
    [
      Slack.Block.Image("https://media.giphy.com/media/oe33xf3B50fsc/giphy.gif", "explosion"),
      Slack.Block.Section(Intent.error(None)),
    ] |> Slack.Block.stringify
  Slack.sendMessage(
    client,
    List.concat(list{
      args,
      list{("text", "Une erreur est survenue"), ("blocks", blocks)},
    }) |> Js.Dict.fromList,
  )
}

let sendGreeting = (message: Message.message) => {
  let answer = GreetHandler.greet(message.userId)
  let args = switch message.threadId {
  | Some(ts) => list{
      ("channel", message.channel),
      ("text", answer),
      ("token", Slack.token),
      ("thread_ts", ts),
    }
  | None => list{("channel", message.channel), ("text", answer), ("token", Slack.token)}
  } |> Js.Dict.fromList

  Slack.sendMessage(client, args)
}

let sendUnknown = (message: Message.message) => {
  let answer = UnknownHandler.handle(message)
  let args = switch message.threadId {
  | Some(ts) => list{
      ("channel", message.channel),
      ("text", answer),
      ("token", Slack.token),
      ("thread_ts", ts),
    }
  | None => list{("channel", message.channel), ("text", answer), ("token", Slack.token)}
  } |> Js.Dict.fromList

  Slack.sendMessage(client, args)
}

let sendVersion = (message: Message.message) => {
  let answer = VersionHandler.handle(message)
  let args = switch message.threadId {
  | Some(ts) => list{
      ("channel", message.channel),
      ("text", answer),
      ("token", Slack.token),
      ("thread_ts", ts),
    }
  | None => list{("channel", message.channel), ("text", answer), ("token", Slack.token)}
  } |> Js.Dict.fromList

  Slack.sendMessage(client, args)
}

let sendNews = (message: Message.message) => {
  open Js.Promise

  let args = {
    switch message.threadId {
    | Some(ts) => list{("channel", message.channel), ("token", Slack.token), ("thread_ts", ts)}
    | None => list{("channel", message.channel), ("token", Slack.token)}
    }
  }
  NewsHandler.getNews(message, ()) |> then_(result => {
    switch result {
    | Ok(articles) => {
        let blocks = Array.map((article: NewsAPI.article) => {
          let title = "<" ++ article.url ++ "|" ++ article.title ++ ">"
          Slack.Block.SectionWithAccessory(title, article.imageUrl, article.title)
        }, articles) |> Slack.Block.stringify
        Slack.sendMessage(
          client,
          List.concat(list{
            args,
            list{("text", `les actualités sont arrivées`), ("blocks", blocks)},
          }) |> Js.Dict.fromList,
        )
      }
    | Error(_) => sendError(message) |> resolve
    }
  })
}

let sendAffirmative = (message: Message.message, intent) => {
  let text = Intent.affirmative(intent)
  let args = switch message.threadId {
  | Some(ts) => [
      ("channel", message.channel),
      ("text", text),
      ("token", Slack.token),
      ("thread_ts", ts),
    ]
  | None => [("channel", message.channel), ("text", text), ("token", Slack.token)]
  } |> Js.Dict.fromArray
  Slack.sendMessage(client, args)
}

let sendRandom = (message: Message.message) => {
  open Js.Promise
  let botUserId = message.botId
  let _ = Slack.getMembers(client, message.channel) |> then_(result => {
    switch result {
    | Ok(resultPayload) => {
        let members =
          List.filter(
            userId => userId !== botUserId,
            resultPayload["members"] |> Belt.List.fromArray,
          ) |> Belt.List.toArray
        let args =
          [
            ("channel", message.channel),
            ("text", RandomHandler.handle(message, members)),
            ("token", Slack.token),
          ] |> Js.Dict.fromArray
        switch message.threadId {
        | Some(ts) => Js.Dict.set(args, "thread_ts", ts)
        | None => ()
        }
        Slack.sendMessage(client, args)
      }
    | Error(_) => sendError(message)
    } |> resolve
  })
}

let processEventPayload = payload => {
  let message = getMessage(payload)
  let intent = Intent.resolve(message)
  switch intent {
  | Intent.Unknown =>
    let _ = sendUnknown(message)
  | Intent.NothingToDo => ()
  | Intent.News => {
      let _ = sendAffirmative(message, intent) |> Js.Promise.then_(_ => {
        Js.Promise.resolve(sendNews(message))
      })
    }
  | Intent.Version => {
      let _ = sendAffirmative(message, intent) |> Js.Promise.then_(_ => {
        Js.Promise.resolve(sendVersion(message))
      })
    }
  | Intent.Greeting =>
    let _ = sendGreeting(message)
  | Intent.Random =>
    let _ = sendAffirmative(message, intent) |> Js.Promise.then_(_ => {
      Js.Promise.resolve(sendRandom(message))
    })
  }
}

let middleware = Middleware.from((_, req, res) => {
  let body = Request.bodyJSON(req)
  switch body {
  | Some(json) =>
    switch Decoder.getPayload(json) {
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
