type intent = Greeting | News | Random | Unknown

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

let toString = intent => {
  switch intent {
  | Greeting => "greeting"
  | News => "news"
  | Random => "random"
  | Unknown => "unknown"
  }
}

let affirmative = _ => Utils.random(responses)

let error = _ => Utils.random(errorResponses)
