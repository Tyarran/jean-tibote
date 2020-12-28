type v2
type t = {apiKey: string}

type article = {
  title: string,
  url: string,
  imageUrl: string,
}
let placeholder = "https://via.placeholder.com/150"

let make = apiKey => {
  apiKey: apiKey,
}

let decodeArticle = json => {
  open Json.Decode
  {
    title: field("title", string, json),
    url: field("url", string, json),
    imageUrl: field("urlToImage", string, json),
  }
}

let decodeStringWithDefault = (jsonValue, default) =>
  switch jsonValue |> Js.Json.decodeString {
  | Some(value) => value
  | None => default
  }

let topHeadlinesUrl = "http://newsapi.org/v2/top-headlines"

let topHeadlines = (api, ~language="fr", ()) => {
  open Js.Promise
  let apiKey = api.apiKey
  let url = topHeadlinesUrl ++ "?apiKey=" ++ apiKey ++ "&language=" ++ language
  Axios.get(url)
  |> then_(response => {
    let articles = Array.map(item => decodeArticle(item), response["data"]["articles"])
    Ok(articles) |> resolve
  })
  |> catch(error => Error(error) |> resolve)
}
