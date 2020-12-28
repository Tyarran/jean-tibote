open Express

let app = App.make()
App.use(app, Middleware.json())

let start = (port, onListenFunc) => {
  App.listen(app, ~port, ~onListen=onListenFunc, ())
}

let registerMiddleware = (~path, method: Request.httpMethod, middleware) => {
  let func = switch method {
  | Request.Get => App.get
  | Request.Post => App.post
  | Request.Patch => App.patch
  | Request.Put => App.put
  | Request.Delete => App.delete
  | _ => App.get
  }
  func(~path, app, middleware)
  true
}
