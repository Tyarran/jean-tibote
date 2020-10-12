type newsapi;
type v2;
type t = {
  apiKey: string,
  api: v2,
};

type article = {
  title: string,
  url: string,
  imageUrl: string,
};
let placeholder = "https://via.placeholder.com/150";

module NewsAPIJS = {
  [@bs.new] [@bs.module] external newsAPI: string => newsapi = "newsapi";
  [@bs.get] external getV2: newsapi => v2 = "v2";
  [@bs.send]
  external topHeadlines: (v2, Js.Dict.t(string)) => Js.Promise.t('a) =
    "topHeadlines";
};

let make = apiKey => {
  let api = NewsAPIJS.newsAPI(apiKey);
  {apiKey, api: NewsAPIJS.getV2(api)};
};

let decodeStringWithDefault = (jsonValue, default) => {
  switch (jsonValue |> Js.Json.decodeString) {
  | Some(value) => value
  | None => default
  };
};

let topHeadlines = (api, params) => {
  Js.Dict.set(params, "apiKey", api.apiKey);
  NewsAPIJS.topHeadlines(api.api, params)
  |> Js.Promise.then_(response => {
       Array.map(
         item => {
           {
             title: decodeStringWithDefault(item##title, ""),
             url: decodeStringWithDefault(item##url, ""),
             imageUrl: decodeStringWithDefault(item##urlToImage, placeholder),
           }
         },
         response##articles,
       )
       |> Js.Promise.resolve
     });
};
