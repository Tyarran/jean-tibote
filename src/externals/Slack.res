type t

type messageArgs = {
  channel: string,
  thread_ts: option<string>,
  text: string,
  token: string,
}

let token = Settings.slackToken

module SlackJS = {
  @bs.module @bs.new external _new: string => t = "slack"

  module Chat = {
    type c
    @bs.get external chat: t => c = "chat"
    @bs.send external postMessage: (c, 'a) => Js.Promise.t<'b> = "postMessage"
  }
}

let make = token => SlackJS._new(token)

module Block = {
  type t =
    | Divider
    | Section(string)
    | SectionWithAccessory(string, string, string)
    | Context(string, string, string)
    | Header(string)

  let buildText = text =>
    [("type", Js.Json.string("mrkdwn")), ("text", Js.Json.string(text))]
    |> Js.Dict.fromArray
    |> Js.Json.object_

  let buildPlainText = text =>
    [
      ("type", Js.Json.string("plain_text")),
      ("text", Js.Json.string(text)),
      ("emoji", Js.Json.boolean(true)),
    ]
    |> Js.Dict.fromArray
    |> Js.Json.object_

  let buildImage = (url, alt_text) =>
    [
      ("type", Js.Json.string("image")),
      ("image_url", Js.Json.string(url)),
      ("alt_text", Js.Json.string(alt_text)),
    ]
    |> Js.Dict.fromArray
    |> Js.Json.object_

  let buildContext = (textContent, image_url, alt_text) => {
    let text = buildText(textContent)
    let image = buildImage(image_url, alt_text)
    [("type", Js.Json.string("context")), ("elements", Js.Json.array([image, text]))]
    |> Js.Dict.fromArray
    |> Js.Json.object_
  }

  let buildSession = text => {
    let textJson = Js.Json.object_(
      Js.Dict.fromArray([("type", Js.Json.string("mrkdwn")), ("text", Js.Json.string(text))]),
    )
    Js.Json.object_(Js.Dict.fromArray([("type", Js.Json.string("section")), ("text", textJson)]))
  }

  let buildSessionWithAccessory = (textContent, image_url, alt_text) => {
    let text = buildText(textContent)
    let accessory = buildImage(image_url, alt_text)
    Js.Json.object_(
      Js.Dict.fromArray([
        ("type", Js.Json.string("section")),
        ("text", text),
        ("accessory", accessory),
      ]),
    )
  }

  let buildHeader = textContent => {
    let text = buildPlainText(textContent)
    [("type", Js.Json.string("header")), ("text", text)] |> Js.Dict.fromArray |> Js.Json.object_
  }

  let build = block => {
    let attributes = switch block {
    | Divider => [("type", Js.Json.string("divider"))] |> Js.Dict.fromArray |> Js.Json.object_
    | Section(text) => buildSession(text)
    | SectionWithAccessory(text, image_url, alt_text) =>
      buildSessionWithAccessory(text, image_url, alt_text)
    | Context(text, image_url, alt_text) => buildContext(text, image_url, alt_text)
    | Header(text) => buildHeader(text)
    }
    attributes
  }
}

let sendMessage = (client, args) => {
  let chat = SlackJS.Chat.chat(client)
  SlackJS.Chat.postMessage(chat, args)
}
