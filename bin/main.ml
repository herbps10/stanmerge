open Core_kernel
open Frontend
open Merge

let model_files = ref []

let name = "%%NAME%%"
let usage = "Usage: " ^ name ^ " model_file.stan"

let options =
  Arg.align []

let add_file filename =
  model_files := !model_files@[filename]

let get_ast filename = 
  let res, warnings = Parse.parse_file Parser.Incremental.program filename in
  Warnings.pp_warnings Fmt.stderr warnings ;
  match res with
    | Result.Ok ast -> ast
    | Result.Error err ->
        Errors.pp Fmt.stderr err ;
        exit 1

let main () = 
  Arg.parse options add_file usage ;
  let asts = List.map !model_files ~f:get_ast in
  print_endline 
    (merge_asts asts)
    
  
let () = main ()
