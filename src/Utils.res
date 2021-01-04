let random = stringArray => {
  let choiceNumber = Js.Math.random_int(0, Array.length(stringArray) - 1)
  stringArray[choiceNumber]
}

let buildRegex = expression => {
  Js.Re.fromStringWithFlags("(?:\\W*)(" ++ expression ++ ")(?:\W*)", ~flags="i")
}

let testRegexes = (text, regexes) => {
  switch List.find(regex => {
    switch Js.Re.exec_(regex, text) {
    | None => false
    | Some(_) => true
    }
  }, regexes) {
  | exception Not_found => false
  | _ => true
  }
}

let stringJoin = (separator, stringList) => {
  Belt.List.reduce(stringList, "", (a, b) => a ++ separator ++ b)
}
