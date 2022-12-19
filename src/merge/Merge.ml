open Core_kernel
open Frontend
open Ast

let combine_location_span xloc1 _ = xloc1

let combine_block b1opt b2opt = 
  match (b1opt, b2opt) with 
    | (None, None) -> None
    | (Some b1, None) -> Some b1
    | (None, Some b2) -> Some b2
    | (Some b1, Some b2) -> 
      let { stmts= stmts1; xloc= xloc1 } = b1 in
      let { stmts= stmts2; xloc= xloc2 } = b2 in
      let b = { stmts= stmts1@stmts2; xloc= (combine_location_span xloc1 xloc2) } in
      Some b

(* For now, comments are stripped out *)
let combine_comment _ _ = []

let merge_programs (p1 : Ast.untyped_program) (p2 : Ast.untyped_program) = 
  let { functionblock= bf1
      ; datablock= bd1
      ; transformeddatablock= btd1
      ; parametersblock= bp1
      ; transformedparametersblock= btp1
      ; modelblock= bm1
      ; generatedquantitiesblock= bgq1
      ; comments = c1 } = p1 in
  let { functionblock= bf2
      ; datablock= bd2
      ; transformeddatablock= btd2
      ; parametersblock= bp2
      ; transformedparametersblock= btp2
      ; modelblock= bm2
      ; generatedquantitiesblock= bgq2
      ; comments = c2 } = p2 in
  let bf = (combine_block bf1 bf2) in
  let pnew = { functionblock= bf
    ; datablock= (combine_block bd1 bd2)
    ; transformeddatablock= (combine_block btd1 btd2)
    ; parametersblock= (combine_block bp1 bp2)
    ; transformedparametersblock= (combine_block btp1 btp2)
    ; modelblock= (combine_block bm1 bm2)
    ; generatedquantitiesblock= (combine_block bgq1 bgq2)
    ; comments = (combine_comment c1 c2) } in
  pnew

let merge_asts x = 
  match x with 
    [] -> ""
    | [ast1; ast2] -> Pretty_printing.pretty_print_program (List.fold_left [ast2] ~init:ast1 ~f:merge_programs)
    | ast::asts -> Pretty_printing.pretty_print_program (List.fold_left asts ~init:ast ~f:merge_programs)
