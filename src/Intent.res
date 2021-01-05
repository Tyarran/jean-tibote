type intent = Greeting | News | Random | Version | Help | Ping | Unknown | NothingToDo

let affirmativeResponses = [
  `À vos ordres, captain !`,
  `Mais bien sûr !`,
  `Je fais ça tout de suite !`,
  `Aussitôt dit, aussitôt fait !`,
  `Immediatement !`,
  `C'est comme si c'était fait !`,
  `Avec plaisir !`,
]

let errorResponses = [
  `Oh non ! Je n'ai pas réussi. Je crois que j'ai besoin qu'on me resserre les boulons ...`,
  `Il ne manquait plus que ça : une erreur`,
  `Oups ...`,
  `Je ne me souviens plus trop comment je dois m'y prendre...`,
]

let toString = intent => {
  switch intent {
  | Greeting => "greeting"
  | News => "news"
  | Random => "random"
  | Version => "version"
  | Unknown => "unknown"
  | Help => "help"
  | NothingToDo => "nothing"
  | Ping => "ping"
  }
}

let toLongDescription = intent => {
  switch intent {
  | Greeting => `répondre à un salut amical`
  | News => `envoyer les actualités`
  | Random => `choisir quelqu'un au hasard dans ce canal`
  | Version => `donner le numéro de ma version`
  | Ping => `faire des vérifications sur mon état`
  | _ => ""
  }
}

let affirmative = _ => Utils.random(affirmativeResponses)

let error = _ => Utils.random(errorResponses)

let resolve = (message: Message.message) => {
  let testFuncs = list{
    (News, NewsHandler.isNews),
    (Random, RandomHandler.isRandom),
    (Version, VersionHandler.isVersion),
    (Ping, PingHandler.isPing),
    (Help, HelpHandler.isHelp),
    (Greeting, GreetHandler.isGreeting),
    (Unknown, UnknownHandler.isUnknown),
  }
  let intent = switch List.find(item => {
    let (_, testFunc) = item
    testFunc(message) === true
  }, testFuncs) {
  | exception Not_found => NothingToDo
  | (intent, _) => intent
  }
  Js.log(`Received ${intent |> toString} intent`)
  intent
}
