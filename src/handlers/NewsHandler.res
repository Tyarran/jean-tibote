let expressions = list{`actualité`, `actualités`, `news`}

let regexes = List.map(expression => Utils.buildRegex(expression), expressions)

let isNews = (message: Message.message) =>
  message.isBot === false &&
  (message._type === Message.Type.Mention ||
    (message._type === Message.Type.Message && message.channelType == Message.ChannelType.Im)) &&
  Utils.testRegexes(message.text, regexes)

let getNews = (_, ~language="fr", ()) => {
  open NewsAPI
  let newsapi = make(Settings.newsAPIToken)
  topHeadlines(newsapi, ~language, ())
}
