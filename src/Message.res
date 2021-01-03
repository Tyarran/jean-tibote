module Type = {
  type t = Direct | Mention | Message
  let fromString = typeString => {
    switch typeString {
    | "app_mention" => Mention
    | "message" => Message
    | "im" => Direct
    | _ => Message
    }
  }
}

type message = {
  text: string,
  id: string,
  time: int,
  userId: string,
  channel: string,
  threadId: option<string>,
  botId: string,
  _type: Type.t,
}
