type t
type article

let make: string => t

let topHeadlines: (t, Js.Dict.t<string>) => Js.Promise.t<array<article>>
