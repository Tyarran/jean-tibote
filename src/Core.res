let greetingExpressions = list{"bonjour", "salut", "hi", "hello", "hey"}

let responses = [
  "Hi <@{{user}}> !",
  "Oh <@{{user}}> ! Ravi de te revoir !",
  "Oh <@{{user}}> ! Ravi de te revoir ! Comment vas-tu ?",
  "Bonjour <@{{user}}> !",
  "Salut <@{{user}}> ! Comment vas-tu ?",
  "Coucou <@{{user}}> !",
]

let chooseResponse = responses => {
  let choiceNumber = Js.Math.random_int(0, Array.length(responses) - 1)
  responses[choiceNumber]
}

let rec findExpression = (greetingExpressions, text) => {
  let word = List.hd(greetingExpressions)
  let rest = List.tl(greetingExpressions)

  let tests = list{
    (word, text) => Js.String.startsWith(word, text),
    (word, text) => Js.String.endsWith(word, text),
    (word, text) => Js.String.includes(" " ++ word ++ " ", text),
  }

  switch List.find(testFunc => testFunc(word, text) === true, tests) {
  | exception Not_found =>
    switch rest {
    | list{} => false
    | _ => findExpression(rest, text)
    }
  | _ => true
  }
}

let isGreeting = (botId, threadTs, text) => {
  switch (botId, threadTs) {
  | (None, None) => findExpression(greetingExpressions, text)
  | _ => false
  }
}

let greet = (payload: Events.eventPayload) => {
  let params = {
    "thread_ts": payload.event.ts,
    "token": Settings.slackToken,
    "channel": payload.event.channel,
    "text": Template.render(chooseResponse(responses), {"user": payload.event.user}),
  }
  let slackAPI = Slack.make(Settings.slackToken)
  let chat = Slack.SlackJS.Chat.chat(slackAPI)
  Slack.SlackJS.Chat.postMessage(chat, params) |> Js.Promise.then_(_ =>
    Js.log("Post greeting message : success") |> Js.Promise.resolve
  )
}
