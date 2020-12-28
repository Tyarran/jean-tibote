let newsRegex = %re("/news |news$|news\W+/i")

let isNews = text => {
  switch Js.Re.exec_(newsRegex, text) {
  | None => false
  | Some(_) => true
  }
}
