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

module ChannelType = {
  type t = Im | Channel
  let fromString = channelTypeString => {
    switch channelTypeString {
    | "im" => Im
    | _ => Channel
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
  channelType: ChannelType.t,
  isBot: bool,
}
