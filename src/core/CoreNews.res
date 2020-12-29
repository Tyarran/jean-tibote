let newsExpressions = list{`actualité`, `actualités`, "news"}

let newsRegexes = List.map(expression => Utils.buildRegex(expression), newsExpressions)

let isNews = text => Utils.testRegexes(text, newsRegexes)
