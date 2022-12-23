open Core_kernel
open Frontend
open Transform

let name = "%%NAME%%"
let usage = "Usage: " ^ name ^ " model_file.stan"
let use_config = ref ""

let options =
  Arg.align
    [
      ( "--config",
        Arg.String (fun s -> use_config := s),
        "Load configuration file" );
    ]

let model_files = ref []
let add_file filename = model_files := !model_files @ [ filename ]

let get_ast filename =
  let res, warnings = Parse.parse_file Parser.Incremental.program filename in
  Warnings.pp_warnings Fmt.stderr warnings;
  match res with
  | Result.Ok ast -> ast
  | Result.Error err ->
      Errors.pp Fmt.stderr err;
      exit 1

let get_ast_from_config (model_file, rules) =
  let ast = get_ast model_file in
  List.fold rules ~init:ast ~f:(fun acc (x, y) ->
      Transform.Rename.rename_variable (Str.regexp x) y acc)

type rule = string * string
type rules = rule list
type config = (string, rules, String.comparator_witness) Map.t

let parse_rule (name, value) =
  match value with `String s -> (name, s) | _ -> (name, "")

let parse_rules (name, values) =
  let parsed_values =
    List.map ~f:parse_rule (Yojson.Basic.Util.to_assoc values)
  in
  (name, parsed_values)

let main () =
  Arg.parse options add_file usage;
  if String.compare !use_config "" <> 0 then
    let json = Yojson.Basic.from_file !use_config in
    let config = List.map ~f:parse_rules (Yojson.Basic.Util.to_assoc json) in
    let asts = List.map ~f:get_ast_from_config config in
    print_endline (Merge.merge_asts asts)
  else
    let asts = List.map !model_files ~f:get_ast in
    let asts_renamed =
      List.map asts
        ~f:(Transform.Rename.rename_variable (Str.regexp "var") "alpha")
    in
    print_endline (Merge.merge_asts asts_renamed)

let () = main ()
