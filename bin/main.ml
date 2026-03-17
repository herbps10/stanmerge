open Core
open Frontend
open Transform

let get_ast filename =
  let res, warnings = Parse.parse_program (`File filename) in
  Warnings.pp_warnings Fmt.stderr warnings;
  match res with
  | Result.Ok ast -> ast
  | Result.Error err ->
      Errors.pp Fmt.stderr err;
      exit 1

let get_ast_from_config (model_file, rules) =
  let ast = get_ast model_file in
  List.fold rules ~init:ast ~f:(fun acc (x, y) ->
      Transform.Rename.rename_variable x y acc)

let parse_rule (name, value) =
  match value with `String s -> (name, s) | _ -> (name, "")

let parse_rules (name, values) =
  let parsed_values =
    List.map ~f:parse_rule (Yojson.Basic.Util.to_assoc values)
  in
  (name, parsed_values)

let run_with_config config_file =
  let json =
    try Yojson.Basic.from_file config_file with
    | Sys_error e ->
      Printf.eprintf "%s\n" e;
      exit 1
    | Yojson.Json_error e ->
      Printf.eprintf "JSON error: %s\n" e;
      exit 1
  in
  let config = List.map ~f:parse_rules (Yojson.Basic.Util.to_assoc json) in
  let asts = List.map ~f:get_ast_from_config config in
  print_endline (Merge.merge_asts asts)

let run_with_files model_files =
  let asts = List.map model_files ~f:get_ast in
  print_endline (Merge.merge_asts asts)

let command = 
  Command.basic 
    ~summary: "Merge Stan models"
    ~readme:(fun () ->
      String.concat ~sep:"\n"
      [ "This tool merges multiple Stan models together, block-by-block."
      ; ""
      ; "Examples:"
      ; "stanmerge model1.stan model2.stan"
      ; ""
      ; "stanmerge --config merge.json"
      ])
    (let%map_open.Command config = 
      flag "--config" (optional string)
        ~doc:"FILE JSON configuration file specifying Stan files to merge"
      and model_files =
        anon (sequence ("MODEL_FILE" %: string))
      in
      fun() ->
      match config with
        | Some config_file -> run_with_config config_file
        | None -> 
          if List.is_empty model_files then (
            eprintf "Error: No model files or config provided.\n";
            exit 1)
          else run_with_files model_files)

let () = Command_unix.run ~version:"0.1.0" command
