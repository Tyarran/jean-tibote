let greetingExpressions = list{
  "bonjour",
  "salut",
  "salutation",
  "salutations",
  "hi",
  "hello",
  "hey",
}

let regexes = List.map(expression => Utils.buildRegex(expression), greetingExpressions)

let responses = [
  `Hi <@{{user}}> !`,
  `Oh <@{{user}}> ! Ravi de te revoir !`,
  `Oh <@{{user}}> ! Excellente journée`,
  `Bonjour <@{{user}}> !`,
  `Salut <@{{user}}> ! je te souhaite une agréable journée !`,
  `coucou <@{{user}}> !`,
]

let isGreeting = (message: Message.message) =>
  message.isBot === false &&
  (message._type === Message.Type.Mention ||
    (message._type === Message.Type.Message && message.channelType == Message.ChannelType.Im)) &&
  Utils.testRegexes(message.text, regexes)

let greet = user => Template.render(Utils.random(responses), {"user": user})
