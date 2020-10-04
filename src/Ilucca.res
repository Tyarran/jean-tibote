open Js.Promise

type t = {apiKey: string}
type apiEndpoint = Groups | Leaves

let make = apiKey => {
  {apiKey: apiKey}
}

let baseUrl = "https://meilleursagents.ilucca.net/api/"

module Team = {
  module Member = {
    type t = {
      id: int,
      name: string,
      url: string,
    }

    let fromObject = obj => {
      {
        id: obj["id"],
        name: obj["name"],
        url: obj["url"],
      }
    }
  }

  type t = {
    name: string,
    members: array<Member.t>,
  }

  let fromObject = obj => {
    let members = Array.map(Member.fromObject, obj["users"])
    {
      name: obj["name"],
      members: members,
    }
  }

  let memberIds = team => Array.map((member: Member.t) => member.id, team.members)

  let isMember = (team, id) => {
    Belt.List.has(memberIds(team) |> Belt.List.fromArray, id, (a, b) => a === b)
  }
}

module Leave = {
  type leaveScope = AM | PM | Day
  type t = {member: Team.Member.t, scope: leaveScope, date: Js.Date.t}

  let fromObject = (obj, ~scope) => {
    let leaveScope = switch scope {
    | Some(value) => value
    | None =>
      switch obj["leaveScope"] {
      | "AM" => AM
      | "PM" => PM
      | _ => Day
      }
    }
    let member: Team.Member.t = {
      id: obj["owner"]["id"],
      name: obj["owner"]["name"],
      url: obj["owner"]["url"],
    }
    {
      member: member,
      scope: leaveScope,
      date: Js.Date.fromString(obj["date"]),
    }
  }
}

let addAuthToken = (api, url) => {
  url ++
  switch Js.String2.includes(url, "?") {
  | true => "&"
  | false => "?"
  } ++
  "authToken=" ++
  api.apiKey
}

let getUrl = (api, endpoint) => {
  let url = switch endpoint {
  | Groups => baseUrl ++ "groups/"
  | Leaves => baseUrl ++ "leaves/?fields=date,leaveScope,owner"
  }
  addAuthToken(api, url)
}

let getGroup = api => {
  Axios.get(getUrl(api, Groups)) |> then_(response => {
    response["data"]["data"][0] |> resolve
  })
}

let getTeam = (api, groupPromise) => {
  groupPromise |> then_(group => {
    let url = group["url"]
    Axios.get(addAuthToken(api, url)) |> then_(response => {
      Team.fromObject(response["data"]["data"]) |> resolve
    })
  })
}

let getLeaves = (api, date) => {
  let map = Belt.HashMap.Int.make(~hintSize=10)
  Axios.get(getUrl(api, Leaves)) |> then_(response => {
    response["data"]["data"] |> Array.iter(leave => {
      let ownerId = leave["owner"]["id"]
      switch Belt.HashMap.Int.get(map, ownerId) {
      | Some(_) =>
        Belt.HashMap.Int.set(map, ownerId, Leave.fromObject(leave, ~scope=Some(Leave.Day)))
      | None => Belt.HashMap.Int.set(map, ownerId, Leave.fromObject(leave, ~scope=None))
      }
    })
    Belt.Array.map(map |> Belt.HashMap.Int.toArray, item => {
      let (_, leave) = item
      leave
    }) |> resolve
  })
}

let getTeamLeaves = (api, date, teamPromise) => {
  let filterDate = date |> Js.Date.toString |> Js.Date.fromString
  let _ = Js.Date.setHoursMSMs(
    filterDate,
    ~hours=0.0,
    ~minutes=0.0,
    ~seconds=0.0,
    ~milliseconds=0.0,
    (),
  )

  Js.Promise.all2((teamPromise, getLeaves(api, date))) |> then_(response => {
    let (team, leaves) = response
    Belt.List.filter(leaves |> Belt.List.fromArray, (leave: Leave.t) =>
      Team.isMember(team, leave.member.id) && leave.date == filterDate
    )
    |> Belt.List.toArray
    |> resolve
  })
}
