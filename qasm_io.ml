(* Copyright 2019 Chetan Murthy, All rights reserved. *)

open OUnit2
open Misc_functions
open Coll
open Qasmlex
open Qasmsyntax
open Qasmparser
open Qasmpp
open Qasmdag0
open Qasm_passes


let full_to_dag0 ~path txt =
  let (_, pl) = full_parse ~path PA.mainprogram txt in
  let (envs, p) = TYCHK.program pl in
  let dag = DAG.make envs p in
  (envs, dag)

let program_to_dag0 ~path txt =
  let pl = body_parse ~path PA.program txt in
  let (envs, p) = TYCHK.program pl in
  let dag = DAG.make envs p in
  (envs, dag)

let parse_to_dag0_to_ast ~path txt =
  let pl = body_parse ~path PA.program txt in
  let (envs, p) = TYCHK.program pl in
  let dag = DAG.make envs p in
  let pl = DAG.to_ast envs dag in  
  pp (ASTPP.program ~skip_qelib:true) pl

let full_to_dag0_from_file ~path fname =
  let vers,pl = full_parse_from_file ~path PA.mainprogram fname in
  let (envs, p) = TYCHK.program pl in
  (envs, DAG.make envs p)

