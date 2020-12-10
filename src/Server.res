open Express
let app = App.make()
App.use(app, Middleware.json())

let middleware = Middleware.from((_, req, res) => {
  let body = Request.bodyJSON(req)
  switch body {
  | Some(json) =>
    switch Events.getPayload(json) {
    | Invalid => Response.sendStatus(Response.StatusCode.Forbidden, res)
    | Challenge(challengeValue) => Response.sendString(challengeValue, res)
    | Event(payload) =>
      switch Core.isGreeting(
        payload.event.botId,
        payload.event.threadTs,
        payload.event.text |> Js.String.toLowerCase,
      ) {
      | true =>
        let _ = Core.greet(payload)
      | false => ()
      }
      Response.sendStatus(Response.StatusCode.Ok, res)
    }
  | None => Response.sendString("Invalid payload", res)
  }
})

let start = port => {
  App.post(~path="/", app, middleware)
  App.get(~path="/", app, middleware)

  App.listen(
    app,
    ~port,
    ~onListen=_ => {
      Js.Console.info(`Listening on port ${Belt.Int.toString(port)}`)
      Js.Console.info("Jean Tibot is ready to work ;)")
    },
    (),
  )
}

start(Settings.appPort)
