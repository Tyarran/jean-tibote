let _ = SlackAPI.init("/slack")
let _ = API.start(Settings.appPort, _ => {
  Js.Console.info(`Listening on port ${Belt.Int.toString(Settings.appPort)}`)
  Js.Console.info("Jean Tibote is ready to work ;)")
})
