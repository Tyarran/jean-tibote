let expressions = list{`version`, `ta version`, `ton age`, `age`}
let responses = ["Je suis en version : `{{version}}`", "Ma version `{{version}}`"]

let regexes = List.map(expression => Utils.buildRegex(expression), expressions)

let isVersion = (message: Message.message) =>
  message.isBot === false &&
  (message._type === Message.Type.Mention ||
    (message._type === Message.Type.Message && message.channelType == Message.ChannelType.Im)) &&
  Utils.testRegexes(message.text, regexes)

let handle = (_: Message.message) =>
  Template.render(Utils.random(responses), {"version": Settings.appVersion})
