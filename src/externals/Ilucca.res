open Js.Promise

type t = {
  apiKey: string,
  baseUrl: string,
}

type apiEndpoint =
  | Groups
  | Users
  | Leaves

let make = (apiKey, baseUrl) => {
  apiKey: apiKey,
  baseUrl: baseUrl,
}

module Team = {
  module Member = {
    type picture = {
      id: string,
      name: string,
      url: string,
    }
    type t = {
      id: int,
      name: string,
      url: string,
      picture: picture,
      role: string,
    }

    let fromObject = obj => {
      let picture = {
        id: obj["picture"]["id"],
        name: obj["picture"]["name"],
        url: obj["picture"]["url"],
      }
      {
        id: obj["id"],
        name: obj["name"],
        url: obj["url"],
        picture: picture,
        role: obj["jobTitle"],
      }
    }
  }

  type t = {
    name: string,
    members: array<Member.t>,
  }

  let make = (name, members) => {
    name: name,
    members: members,
  }
}

module Leave = {
  type leaveScope =
    | AM
    | PM
    | Day

  type t = {
    member: Team.Member.t,
    scope: leaveScope,
    date: Js.Date.t,
  }

  let fromObject = (obj, team: Team.t, ~scope) => {
    let scope = switch scope {
    | Some(value) => value
    | None =>
      switch obj["scope"] {
      | 0 => AM
      | 1 => PM
      | _ => Day
      }
    }
    let member =
      team.members
      |> Belt.List.fromArray
      |> List.filter((member: Team.Member.t) => member.id === obj["ownerID"])
      |> Belt.List.toArray
    {member: member[0], scope: scope, date: Js.Date.fromString(obj["date"])}
  }
}

let addAuthToken = (api, url) =>
  url ++ ((Js.String2.includes(url, "?") ? "&" : "?") ++ ("authToken=" ++ api.apiKey))

let getUrl = (api, endpoint) => {
  let url = switch endpoint {
  | Groups => api.baseUrl ++ "groups/"
  | Users => api.baseUrl ++ "users/"
  | Leaves => api.baseUrl ++ "leaves?fields=scope,date,OwnerId"
  }
  addAuthToken(api, url)
}

let getGroup = api => {
  let url = getUrl(api, Groups)
  Axios.get(url) |> then_(response => response["data"]["data"]["items"][0] |> resolve)
}

let getTeam = api => getGroup(api) |> then_(group => {
    let url = group["url"]
    Axios.get(addAuthToken(api, url)) |> then_(response => {
      let urls = Array.map(member => {
        let inst = Axios.Instance.create(Axios.makeConfig(~validateStatus=_ => true, ()))
        Axios.Instance.get(inst, api.baseUrl ++ ("users/" ++ member["id"]) |> addAuthToken(api))
      }, response["data"]["data"]["members"])

      Axios.all(urls) |> then_(responses => {
        let members =
          Belt.List.fromArray(responses)
          |> List.filter(response => response["status"] === 200)
          |> List.map(response => Team.Member.fromObject(response["data"]["data"]))
          |> Belt.List.toArray
        Js.log(members)
        Team.make(response["data"]["data"]["name"], members) |> resolve
      })
    })
  })

let buildOwnerIdStringList = (team: Team.t) => {
  let ids = Array.map((member: Team.Member.t) => member.id, team.members)
  Js.Array2.joinWith(ids, ",")
}

let groupLeaves = leaves => {
  let map = Belt.HashMap.Int.make(~hintSize=10)
  Array.iter((leave: Leave.t) =>
    switch Belt.HashMap.Int.get(map, leave.member.id) {
    | Some(_) => Belt.HashMap.Int.set(map, leave.member.id, {...leave, scope: Leave.Day})
    | None => Belt.HashMap.Int.set(map, leave.member.id, leave)
    }
  , leaves)
  Belt.HashMap.Int.toArray(map) |> Array.map(item => {
    let (_, leave) = item
    leave
  })
}

let buildDateString = date =>
  (Js.Date.getFullYear(date) |> int_of_float |> string_of_int) ++
    ("-" ++
    ((Js.Date.getMonth(date) +. 1.0 |> int_of_float |> string_of_int) ++
      ("-" ++
      (Js.Date.getDate(date) |> int_of_float |> string_of_int))))

let buildLeaveUrl = (baseUrl, team, dateString) =>
  baseUrl ++
  ("&date=between," ++
  (dateString ++
  ("," ++
  (dateString ++ ("&leavePeriod.ownerId=" ++ buildOwnerIdStringList(team))))))

let getLeavesOfTheDay = (api, date, teamPromise) => {
  let dateString = buildDateString(date)
  teamPromise |> then_(team => {
    let url = buildLeaveUrl(getUrl(api, Leaves), team, dateString)
    Axios.get(url) |> then_(response => {
      let items = response["data"]["data"]["items"]
      Array.map(item => Leave.fromObject(item, team, ~scope=None), items) |> groupLeaves |> resolve
    })
  })
}
