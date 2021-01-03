let expressions = list{`actualité`, `actualités`, `news`}

let regexes = List.map(expression => Utils.buildRegex(expression), expressions)

let isNews = (message: Message.message) =>
  message._type === Message.Type.Mention && Utils.testRegexes(message.text, regexes)

let getNews = (_, ~language="fr", ()) => {
  open NewsAPI
  let newsapi = make(Settings.newsAPIToken)
  topHeadlines(newsapi, ~language, ())
}
