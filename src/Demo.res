type envType
@bs.val external env: envType = "process.env"
@bs.get_index external getEnv: (envType, string) => string = ""

let apiKey = getEnv(env, "ILUCCA_API_KEY")

let iLuccaAPI = Ilucca.make(apiKey)

Ilucca.getGroup(iLuccaAPI)
|> Ilucca.getTeam(iLuccaAPI)
|> Ilucca.getTeamLeaves(iLuccaAPI, Js.Date.fromString("2020-10-05:00:00.000Z"))
|> Js.Promise.then_(result => Js.log(result) |> Js.Promise.resolve)
