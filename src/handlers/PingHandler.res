let expressions = list{
  `ping`,
  `test`,
  `check`,
  `vérifications`,
  `état`,
  `state`,
  `check-up`,
  `checkup`,
  `bilan de santé`,
}

let regexes = List.map(expression => Utils.buildRegex(expression), expressions)

let responses = [
  `Je suis là mon général !`,
  `Présent`,
  `Yes !`,
  `Chef, oui Chef !`,
  `Pong !`,
  `Tout est pour moi.`,
]

let isPing = (message: Message.message) =>
  message.isBot === false &&
  (message._type === Message.Type.Mention ||
    (message._type === Message.Type.Message && message.channelType == Message.ChannelType.Im)) &&
  Utils.testRegexes(message.text, regexes)

let handle = (_: Message.message) => Utils.random(responses)
