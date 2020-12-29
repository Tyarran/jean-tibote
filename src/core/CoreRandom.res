let randomExpressions = list{
  "random",
  "au hasard",
  "tirer au sort",
  "tires au sort",
  "choisis quelqu'un",
}

let randomRegexes = List.map(expression => Utils.buildRegex(expression), randomExpressions)

let responses = [
  `L'heureux élu est: <@{{user}}> ! :tada:`,
  `Félicitons <@{{user}}> !`,
  `<@{{user}}> ! La personne que je préfére en plus !`,
  `C'est ton jour de chance <@{{user}}> !`,
]

let isRandom = text => Utils.testRegexes(text, randomRegexes)

let chooseMember = members => Utils.random(members)

let response = user => {
  Template.render(Utils.random(responses), {"user": user})
}
