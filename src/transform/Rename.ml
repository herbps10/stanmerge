open Core_kernel
open Frontend
open Ast

let rename_variable_identifier x y id = 
  (* if (String.compare id.name x) = 0 then { id with name = y } else id *)
  { id with name = ( Str.global_replace x y id.name ) }

let rec rename_variable_expr x y { expr; emeta } = 
  match expr with
  | Variable id -> { expr = Variable (rename_variable_identifier x y id); emeta }
  (*| PrefixOp (op, e) -> { expr = PrefixOp (op, (rename_variable_expr x y e)); emeta }
  | PostfixOp (e, op) -> { expr = PostfixOp ((rename_variable_expr x y e), op);
  emeta }*)
  | _ -> { expr = map_expression (rename_variable_expr x y) ident expr
          ; emeta }

(* This function is adapted from lib/stanc3/stanc3/src/frontend/Canonicalize.ml,
   originally licensed under BSD 3-Clause license (lib/stanc3/stanc3/LICENSE)
*)
let rename_variable_lval x y { lval; lmeta } = 
  let is_multiindex = function
    | Single _ -> false
    | _ -> true in
  let rec flatten_multi = function
    | LVariable id -> ( LVariable ( rename_variable_identifier x y id ), None)
    | LIndexed ({lval; lmeta}, idcs) -> (
        let outer =
          List.map idcs
            ~f:(map_index (rename_variable_expr x y))
        in
        let unwrap = Option.value_map ~default:[] ~f:fst in
        match flatten_multi lval with
        | lval, inner when List.exists ~f:is_multiindex outer ->
            (lval, Some (unwrap inner @ outer, lmeta))
        | lval, None -> (LIndexed ({lval; lmeta}, outer), None)
        | lval, Some (inner, _) -> (lval, Some (inner @ outer, lmeta)) ) in
  let lval =
    match flatten_multi lval with
    | lval, None -> lval
    | lval, Some (idcs, lmeta) -> LIndexed ({lval; lmeta}, idcs) in
  {lval; lmeta} 

let rename_variable_var x y { identifier; initial_value } =
  let id = rename_variable_identifier x y identifier in
  match initial_value with 
    | Some e -> 
        let init = (Some (rename_variable_expr x y e)) in
        { identifier = id; initial_value = init }
    | None -> { identifier = id; initial_value }

let rec rename_variable_stmt x y ({ stmt; smeta } : untyped_statement) : untyped_statement = 
  let stmt = match stmt with
  | VarDecl { decl_type; transformation; variables; is_global } ->
      VarDecl { decl_type
      ; transformation
      ; variables = List.map ~f:(rename_variable_var x y) variables
      ; is_global }
  | For {loop_variable; lower_bound; upper_bound; loop_body} ->
    For { 
      loop_variable = rename_variable_identifier x y loop_variable;
      lower_bound = rename_variable_expr x y lower_bound;
      upper_bound = rename_variable_expr x y upper_bound;
      loop_body = rename_variable_stmt x y loop_body
    }
  | _ -> map_statement
           (rename_variable_expr x y)
           (rename_variable_stmt x y)
           (rename_variable_lval x y)
           ident 
           stmt in
  { stmt = stmt; smeta }

let rename_variable x y ast = 
  ast |> map_program (rename_variable_stmt x y)
