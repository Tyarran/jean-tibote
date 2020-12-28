module Args = {
  type t

  external string: string => t = "%identity"
  external decodeString: t => string = "%identity"
}

type t = {
  name: string,
  args: Js.Dict.t<Args.t>,
}

type emitter

@bs.module("events") @bs.new external make: unit => emitter = "EventEmitter"
@bs.send external _emit: (emitter, string, t) => bool = "emit"
@bs.send external on: (emitter, string, t => unit) => emitter = "on"

let emit = (emitter, eventName, arguments) => {
  let event: t = {
    name: eventName,
    args: arguments,
  }
  _emit(emitter, eventName, event)
}

let globalEmitter = make()
