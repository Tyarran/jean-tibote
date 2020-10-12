open Js.Promise;

type t = {
  apiKey: string,
  baseUrl: string,
};

type apiEndpoint =
  | Groups
  | Leaves;

let make = (apiKey, baseUrl) => {
  {apiKey, baseUrl};
};

module Team = {
  module Member = {
    type t = {
      id: int,
      name: string,
      url: string,
    };

    let fromObject = obj => {
      {id: obj##id, name: obj##name, url: obj##url};
    };
  };

  type t = {
    name: string,
    members: array(Member.t),
  };

  let fromObject = obj => {
    let members = Array.map(Member.fromObject, obj##members);
    {name: obj##name, members};
  };

  let memberIds = team =>
    Array.map((member: Member.t) => member.id, team.members);

  let isMember = (team, id) => {
    Belt.List.has(memberIds(team) |> Belt.List.fromArray, id, (a, b) =>
      a === b
    );
  };
};

module Leave = {
  type leaveScope =
    | AM
    | PM
    | Day;

  type t = {
    member: Team.Member.t,
    scope: leaveScope,
    date: Js.Date.t,
  };

  let fromObject = (obj, team: Team.t, ~scope) => {
    let scope =
      switch (scope) {
      | Some(value) => value
      | None =>
        switch (obj##scope) {
        | 0 => AM
        | 1 => PM
        | _ => Day
        }
      };
    let member =
      team.members
      |> Belt.List.fromArray
      |> List.filter((member: Team.Member.t) => member.id === obj##ownerID)
      |> Belt.List.toArray;
    {member: member[0], scope, date: Js.Date.fromString(obj##date)};
  };
};

let addAuthToken = (api, url) => {
  url
  ++ (Js.String2.includes(url, "?") ? "&" : "?")
  ++ "authToken="
  ++ api.apiKey;
};

let getUrl = (api, endpoint) => {
  let url =
    switch (endpoint) {
    | Groups => api.baseUrl ++ "groups/"
    /* | Leaves => api.baseUrl ++ "leaves/?fields=date,leaveScope,owner" */
    | Leaves => api.baseUrl ++ "leaves?fields=scope,date,OwnerId"
    };
  addAuthToken(api, url);
};

let getGroup = api => {
  let url = getUrl(api, Groups);
  Axios.get(url)
  |> then_(response => response##data##data##items[0] |> resolve);
};

let getTeam = (api, groupPromise) => {
  groupPromise
  |> then_(group => {
       let url = group##url;
       Axios.get(addAuthToken(api, url))
       |> then_(response => {
            Team.fromObject(response##data##data) |> resolve
          });
     });
};

let buildOwnerIdStringList = (team: Team.t) => {
  let ids = Array.map((member: Team.Member.t) => member.id, team.members);
  Js.Array2.joinWith(ids, ",");
};

let groupLeaves = (team, leaves) => {
  let map = Belt.HashMap.Int.make(~hintSize=10);
  Array.iter(
    (leave: Leave.t) => {
      switch (Belt.HashMap.Int.get(map, leave.member.id)) {
      | Some(_) =>
        Belt.HashMap.Int.set(
          map,
          leave.member.id,
          {...leave, scope: Leave.Day},
        )

      | None => Belt.HashMap.Int.set(map, leave.member.id, leave)
      }
    },
    leaves,
  );
  Belt.HashMap.Int.toArray(map)
  |> Array.map(item => {
       let (_, leave) = item;
       leave;
     });
};

let getLeavesOfTheDay = (api, date, teamPromise) => {
  let endpointUrl = getUrl(api, Leaves);
  let dateString =
    (Js.Date.getFullYear(date) |> int_of_float |> string_of_int)
    ++ "-"
    ++ (Js.Date.getMonth(date) +. 1.0 |> int_of_float |> string_of_int)
    ++ "-"
    ++ (Js.Date.getDate(date) |> int_of_float |> string_of_int);
  teamPromise
  |> then_(team => {
       let url =
         endpointUrl
         ++ "&date=between,"
         ++ dateString
         ++ ","
         ++ dateString
         ++ "&leavePeriod.ownerId="
         ++ buildOwnerIdStringList(team);
       Axios.get(url)
       |> then_(response => {
            let items = response##data##data##items;
            let leaves =
              Array.map(
                item => Leave.fromObject(item, team, ~scope=None),
                items,
              )
              |> groupLeaves(team);

            Js.log(leaves) |> resolve;
          });
     });
};

let getLeaves = api => {
  let map = Belt.HashMap.Int.make(~hintSize=10);
  Axios.get(getUrl(api, Leaves))
  |> then_(response => {
       response##data##data
       |> Array.iter(leave => {
            let ownerId = leave##owner##id;
            switch (Belt.HashMap.Int.get(map, ownerId)) {
            | Some(_) =>
              Belt.HashMap.Int.set(
                map,
                ownerId,
                Leave.fromObject(leave, ~scope=Some(Leave.Day)),
              )
            | None =>
              Belt.HashMap.Int.set(
                map,
                ownerId,
                Leave.fromObject(leave, ~scope=None),
              )
            };
          });
       Belt.Array.map(
         map |> Belt.HashMap.Int.toArray,
         item => {
           let (_, leave) = item;
           leave;
         },
       )
       |> resolve;
     });
};
