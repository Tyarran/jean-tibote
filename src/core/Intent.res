type intent = Greeting | News | Unknown

let responses = [
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

let chooseResponse = responses => {
  let choiceNumber = Js.Math.random_int(0, Array.length(responses) - 1)
  responses[choiceNumber]
}

let toString = intent => {
  switch intent {
  | Greeting => "greeting"
  | News => "news"
  | Unknown => "unknown"
  }
}

let affirmative = _ => {
  chooseResponse(responses)
}

let error = _ => {
  chooseResponse(errorResponses)
}
