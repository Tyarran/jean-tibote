type intent = Greeting | News | Random | Version | Help

let expressions = list{
  `aide`,
  `help`,
  `capacités`,
  `capacité`,
  `tu sais faire`,
  `faire quoi`,
  `features`,
  `feature`,
  `fonctionnalités`,
  `fonctionnalité`,
  `list`,
  `liste`,
}

let intentToHelp = intent => {
  switch intent {
  | Greeting => `- répondre à un salut amical`
  | News => `- envoyer les actualités`
  | Random => `- choisir quelqu'un au hasard dans ce canal`
  | Version => `- donner le numéro de ma version`
  | Help => `- afficher ce message`
  }
}

let regexes = List.map(expression => Utils.buildRegex(expression), expressions)

let intents = list{Greeting, News, Random, Version, Help}

let responses = ["Je sais faire plein de trucs :", "Voici tout ce que je sais faire :"]

let isHelp = (message: Message.message) =>
  message._type === Message.Type.Mention && Utils.testRegexes(message.text, regexes)

let handle = (_: Message.message) => {
  Utils.random(responses) ++ "\n\n" ++ (List.map(intentToHelp, intents) |> Utils.stringJoin("\n"))
}
