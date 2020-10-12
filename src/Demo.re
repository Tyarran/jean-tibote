let iLuccaAPI = Ilucca.make(Settings.iluccaAPIKey, Settings.iluccaAPIBaseUrl);
let slack = Slack.make(Settings.slackToken);

Ilucca.getGroup(iLuccaAPI)
|> Ilucca.getTeam(iLuccaAPI)
|> Ilucca.getLeavesOfTheDay(iLuccaAPI, Js.Date.make());
/* |> Ilucca.getTeamLeaves(iLuccaAPI, Js.Date.make()) */
/* |> Js.Promise.then_(response => Js.log(response) |> Js.Promise.resolve); */
/* |> Js.Promise.then_(result => Js.log(result) |> Js.Promise.resolve); */

/* open Slack.Block; */
/* let apiKey = "443f9b861e564819a110da4738f506af"; */
/* let api = NewsAPI.make(apiKey); */
/* let p = Js.Dict.fromArray([|("language", "fr"), ("country", "fr")|]); */
/* NewsAPI.topHeadlines(api, p) */
/* |> Js.Promise.then_(articles => { */
/*      /1* let articlesSubset = Array.sub(articles##articles, 0, 5); *1/ */
/*      let blocks = */
/*        Array.map( */
/*          (article: NewsAPI.article) => { */
/*            SectionWithAccessory( */
/*              "<" ++ article.url ++ "|" ++ article.title ++ ">", */
/*              article.imageUrl, */
/*              article.title, */
/*            ) */
/*          }, */
/*          articles, */
/*        ) */
/*        |> Belt.List.fromArray; */
/*      let blockString = */
/*        List.map(Slack.Block.build, blocks) */
/*        |> Belt.List.toArray */
/*        |> Js.Json.array; */

/*      let params = */
/*        Js.Dict.fromArray([| */
/*          ("token", slackToken), */
/*          ("channel", channel), */
/*          ("text", "coucou"), */
/*          /1* ("thread_ts", "1602866097.000800"), *1/ */
/*          ("blocks", Js.Json.stringify(blockString)), */
/*        |]); */
/*      Slack.Chat.postMessage(params) */
/*      |> Js.Promise.then_(response => Js.log(response) |> Js.Promise.resolve); */
/*    }); */
