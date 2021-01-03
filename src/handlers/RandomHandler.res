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

let isRandom = (message: Message.message) =>
  message._type === Message.Type.Mention && Utils.testRegexes(message.text, randomRegexes)

let chooseMember = members => Utils.random(members)

let handle = (message: Message.message, members) => {
  Js.log("Handle random message")
  Js.log(message)
  let member = chooseMember(members)
  Template.render(Utils.random(responses), {"user": member})
}
