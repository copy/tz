let tz_aliases = [
  (* TODO *)
  "Germany", "Europe/Berlin";
  "Mexico", "America/Mexico_City";
  "India", "Asia/Kolkata"
]

let tr search replacement s = String.concat replacement (String.split_on_char search s)
let tz_offset z = List.hd (List.rev (Timedesc.Time_zone.recorded_offsets z))
let lowercase_compare s1 s2 = compare (String.lowercase_ascii s1) (String.lowercase_ascii s2)
let find_tz name =
  let name = String.lowercase_ascii name in
  match List.find_map (fun (alias, n) -> if lowercase_compare alias name = 0 then Some n else None) tz_aliases with
  | Some n -> Some (Timedesc.Time_zone.make_exn n)
  | None ->
  List.find_map (fun n ->
      if lowercase_compare name n = 0 || List.exists (fun part -> 0 = lowercase_compare part name) (String.split_on_char '/' n) then
        Some (Timedesc.Time_zone.make_exn n)
      else None
    ) Timedesc.Time_zone.available_time_zones
let bold s = String.concat "" ["\x1b[1m"; s; "\x1b[0m"]

let () =
  match Sys.argv with
  | [| _; "--list" |] ->
    List.iter print_endline Timedesc.Time_zone.available_time_zones;
    List.iter (fun (n, _) -> print_endline n) tz_aliases
  | _ ->
  let local = Timedesc.Time_zone.local_exn () in
  let zones =
    Array.sub Sys.argv 1 (Array.length Sys.argv - 1)
    |> Array.map (fun zone_name ->
        match find_tz zone_name with
        | Some z -> z
        | None ->
          Printf.printf "Unknown time zone: %s\nUse --list to show a list of available timezones\n" zone_name;
          exit 1
      )
    |> Array.to_list
    |> List.cons local
    |> List.map (fun z ->
        let name = Timedesc.Time_zone.name z in
        let nice_name =
          match String.split_on_char '/' name with
          | [_; "East" | "West"] -> name
          | [n; "General"] | [_; n] -> n
          | _ -> name
        in
        let nice_name = tr '_' " " nice_name in
        nice_name, z
      )
    |> List.sort_uniq (fun (n1, _) (n2, _) -> compare n1 n2)
    |> List.sort (fun (_, z1) (_, z2) -> compare (tz_offset z1) (tz_offset z2))
  in
  let now = Timedesc.Span.of_float_s (Unix.gettimeofday ()) in
  let one_hour = Timedesc.Span.make ~s:3600L () in
  let half_day = Timedesc.Span.make ~s:(Int64.mul 12L 3600L) () in
  let start = Timedesc.Span.sub now half_day in
  let longest_zone_name = List.map (fun (name, _) -> String.length name) zones |> List.fold_left max 0 in
  List.iter (fun (name, zone) ->
      let offset = match Timedesc.offset_from_utc (Timedesc.of_timestamp_exn ~tz_of_date_time:zone start) with
        | `Single x | `Ambiguous (_, x) -> Timedesc.Span.get_s x |> Int64.to_int
      in
      Printf.printf "%s%s |"
        (if Timedesc.Time_zone.equal zone local then bold name else name)
        (String.make (longest_zone_name - String.length name) ' ');
      Printf.printf " %c%02d |"
        (if offset < 0 then '-' else '+')
        (abs offset / 3600);
      let t = ref start in
      for _i = 0 to 24 do
        let hour = Timedesc.of_timestamp_exn ~tz_of_date_time:zone !t |> Timedesc.hour in
        let hour = Printf.sprintf "%2d" hour in
        Printf.printf " %s" (if !t = now then bold hour else hour);
        t := Timedesc.Span.add !t one_hour;
      done;
      Printf.printf "\n"
    ) zones
