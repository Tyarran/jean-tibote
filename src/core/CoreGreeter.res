let greetingExpressions = list{
  "bonjour",
  "salut",
  "salutation",
  "salutations",
  "hi",
  "hello",
  "hey",
}

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
    (word, text) => word == text,
    (word, text) => Js.String.startsWith(word ++ " ", text),
    (word, text) => Js.String.endsWith(" " ++ word, text),
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

let isGreeting = (botId, threadId, text) => {
  switch (botId, threadId) {
  | (None, None) => findExpression(greetingExpressions, text |> Js.String.toLowerCase)
  | _ => false
  }
}

let greet = user => Template.render(chooseResponse(responses), {"user": user})
