open Coll
open Misc_functions
open Qc_environment
open Qrpc_types
open Qrpc_api

module Login = struct
  type t = {
      rcfile : string option ;
      (** specify rcfile location *)

      key : string option ;
      (** specify section in rcfile *)

      debug : bool ;
      (** turn on all debugging & logging *)
    } [@@deriving cmdliner,show]

  let login p =
    Nethttp_client.Debug.enable := p.debug ;
    let rcfile = match p.rcfile with
      | Some f -> f
      | None -> Defaults._DEFAULT_QISKITRC_FILE in

    let creds = Credentials.mk() in
    Credentials.add_rcfile ~fname:rcfile creds ;
    let session = match p.key with
      | None -> Session.mk creds
      | Some key -> Session.mk ~key creds in
    Session.obtain_token session ;
    session


  let do_login p =
    let session = login p in
    let key = Session.key session in
    let url = Session.get_backends_url session in
    let token = Session.access_token session in
    Printf.printf "key: %s\n" key ;
    Printf.printf "url: %s\n" url ;
    Printf.printf "access_token: %s\n" token ;
    ()

  let cmd =
    let term = Cmdliner.Term.(const do_login $ cmdliner_term ()) in
    let info = Cmdliner.Term.info "login" in
    (term, info)
end

module AvailableBackends = struct
  type t = {
      rcfile : string option ;
      (** specify rcfile location *)

      key : string option ;
      (** specify section in rcfile *)

      debug : bool ;
      (** turn on all debugging & logging *)

      verbose : bool ;
      (** print backend list verbosely *)
    } [@@deriving cmdliner,show]

  let do_available_backends p =
    let { rcfile ; key ; debug; verbose } = p in
    let session = Login.(login { rcfile ; key ; debug }) in
    let l = Session.available_backends session in
    if not verbose then
      l
      |> LM.dom
      |> List.sort Pervasives.compare
      |> String.concat " "
      |> Printf.printf "backends: %s\n"
    else
      LM.app (fun k v ->
          Printf.printf "%s: " k ;
          v |> CoreConfig.to_yojson |> Yojson.Safe.pretty_to_channel stdout ;
          Printf.printf "\n" ;
        ) l

  let cmd =
    let term = Cmdliner.Term.(const do_available_backends $ cmdliner_term ()) in
    let info = Cmdliner.Term.info "available_backends" in
    (term, info)
end

module ListJobs = struct
  type t = {
      rcfile : string option ;
      (** specify rcfile location *)

      key : string option ;
      (** specify section in rcfile *)

      debug : bool ;
      (** turn on all debugging & logging *)

      verbose : bool ;
      (** print backend list verbosely *)

      backend : string ;
      (** the backend to list jobs for *)

    } [@@deriving cmdliner,show]

  let do_list_jobs p =
    let { rcfile ; key ; debug; verbose ; backend } = p in
    let session = Login.(login { rcfile ; key ; debug }) in
    let l = Job.get_status_jobs ~backend session in

    if not verbose then
      let l =
        List.map (fun s ->
            JobStatus.(
                    s.id,
                    s.creationDate,
                    List.map (fun state ->
                        JobState.(state.status, state.executionId)) s.qasms)) l in
      List.iter (fun (id, d, sl) ->
          Printf.printf "%s: created at %s\n" id d;
          List.iter (fun (status, eid) ->
              Printf.printf "\t%s: %s\n" eid status
            ) sl
        ) l
    else
      Printf.printf "You really don't want to see a verbose dump\n"

  let cmd =
    let term = Cmdliner.Term.(const do_list_jobs $ cmdliner_term ()) in
    let info = Cmdliner.Term.info "list_jobs" in
    (term, info)
end

type params = {
  username: string;
  (** Your Github username *)

  api_key: string;
  (** Your Github API key *)

  command: string; [@pos 0] [@docv "CMD"]
  (** The Github API command to run *)

  dry_run: bool;
  (** Don't really run this command *)

  time_to_wait: float; [@default 0.]
  (** Just an example of another type *)
} [@@deriving cmdliner,show]

let print_params p =
  print_string (show_params p) ;
  print_newline()

let _ =
if invoked_as "qctool" then

  let cmd1_term = Cmdliner.Term.(const print_params $ params_cmdliner_term ()) in
  let cmd1_info = Cmdliner.Term.info "cmd1" in

  let cmd2_term = Cmdliner.Term.(const print_params $ params_cmdliner_term ()) in
  let cmd2_info = Cmdliner.Term.info "cmd2" in

  let cmd3_term = Cmdliner.Term.(const print_params $ params_cmdliner_term ()) in
  let cmd3_info = Cmdliner.Term.info "cmd3" in

  Cmdliner.Term.(exit @@ eval_choice (cmd1_term, cmd1_info) [
                             Login.cmd;
                             AvailableBackends.cmd;
                             ListJobs.cmd;
                             (cmd1_term, cmd1_info); (cmd2_term, cmd2_info); (cmd3_term, cmd3_info)])

;;