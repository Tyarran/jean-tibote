type t = {token: string};
[@bs.val] [@bs.scope "JSON"] external loadBlock: string => t = "parse";

module Chat = {
  [@bs.val]
  external postMessage: 'a => Js.Promise.t('b) = "slack.chat.postMessage";
};

module SlackJS = {
  [@bs.module] [@bs.new] external _new: string => t = "slack";
  [@bs.val]
  external listUser: Js.Dict.t(string) => Js.Promise.t('a) =
    "slack.users.list";
};

let make = token => {
  SlackJS._new(token);
};

module Block = {
  type t =
    | Divider
    | Section(string)
    | SectionWithAccessory(string, string, string)
    | Context(string, string, string)
    | Header(string);

  let buildText = text => {
    [|("type", Js.Json.string("mrkdwn")), ("text", Js.Json.string(text))|]
    |> Js.Dict.fromArray
    |> Js.Json.object_;
  };

  let buildPlainText = text => {
    [|
      ("type", Js.Json.string("plain_text")),
      ("text", Js.Json.string(text)),
      ("emoji", Js.Json.boolean(true)),
    |]
    |> Js.Dict.fromArray
    |> Js.Json.object_;
  };

  let buildImage = (url, alt_text) => {
    [|
      ("type", Js.Json.string("image")),
      ("image_url", Js.Json.string(url)),
      ("alt_text", Js.Json.string(alt_text)),
    |]
    |> Js.Dict.fromArray
    |> Js.Json.object_;
  };

  let buildContext = (textContent, image_url, alt_text) => {
    let text = buildText(textContent);
    let image = buildImage(image_url, alt_text);
    [|
      ("type", Js.Json.string("context")),
      ("elements", Js.Json.array([|image, text|])),
    |]
    |> Js.Dict.fromArray
    |> Js.Json.object_;
  };

  let buildSession = text => {
    let textJson =
      Js.Json.object_(
        Js.Dict.fromArray([|
          ("type", Js.Json.string("mrkdwn")),
          ("text", Js.Json.string(text)),
        |]),
      );
    Js.Json.object_(
      Js.Dict.fromArray([|
        ("type", Js.Json.string("section")),
        ("text", textJson),
      |]),
    );
  };

  let buildSessionWithAccessory = (textContent, image_url, alt_text) => {
    let text = buildText(textContent);
    let accessory = buildImage(image_url, alt_text);
    Js.Json.object_(
      Js.Dict.fromArray([|
        ("type", Js.Json.string("section")),
        ("text", text),
        ("accessory", accessory),
      |]),
    );
  };

  let buildHeader = textContent => {
    let text = buildPlainText(textContent);
    [|("type", Js.Json.string("header")), ("text", text)|]
    |> Js.Dict.fromArray
    |> Js.Json.object_;
  };

  let build = block => {
    let attributes =
      switch (block) {
      | Divider =>
        [|("type", Js.Json.string("divider"))|]
        |> Js.Dict.fromArray
        |> Js.Json.object_
      | Section(text) => buildSession(text)
      | SectionWithAccessory(text, image_url, alt_text) =>
        buildSessionWithAccessory(text, image_url, alt_text)
      | Context(text, image_url, alt_text) =>
        buildContext(text, image_url, alt_text)
      | Header(text) => buildHeader(text)
      };
    attributes;
  };
};

/* let test = { */
/*   let array_like = Js.String.castToArrayLike("") */
/*   let monArray = Js.Array.from(array_like) */
/*   Js.Array.push(monArray, {. truc: "chose"}) */
/*   Js.Array.push(monArray, {. machine: "bidule"}) */
/*   monArray */
/* } */

/* Js.log(test) */

/* let list = token => { */
/*   Axios.get("https://slack.com/api/users.list?" ++ "token=") */
/*   |> Js.Promise.then_(response => { */
/*        let members = response##data##members; */
/*        Array.iter(member => Js.log(member##profile##real_name), members) */
/*        |> Js.Promise.resolve; */
/*      }); */
/* }; */
