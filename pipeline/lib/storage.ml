let setup_metadata ~repository (db : Postgresql.connection) =
  Logs.debug (fun log -> log "Inserting metada....");
  let run_at = Sql_util.time (Ptime_clock.now ()) in
  let repo_id = Sql_util.string (Repository.info repository) in
  let commit = Sql_util.string (Repository.commit_hash repository) in
  let branch = Sql_util.(option string) (Repository.branch repository) in
  let pull_number = Sql_util.(option int) (Repository.pull_number repository) in
  let query =
    Fmt.str
      {|
    INSERT INTO
    benchmark_metadata(run_at, repo_id, commit, branch, pull_number)
    VALUES
    (%s, %s, %s, %s, %s)
    ON CONFLICT DO NOTHING
    RETURNING id;
    |}
      run_at repo_id commit branch pull_number
  in
  try
    let result = db#exec query in
    match result#get_all with
    | [| [| id |] |] -> int_of_string id
    | result ->
        Logs.err (fun log ->
            log "Unexpected result for Db.exists %s:%s\n%a"
              (Repository.info repository)
              (Repository.commit_hash repository)
              (Fmt.array (Fmt.array Fmt.string))
              result);
        -1
  with exn ->
    Logs.err (fun log ->
        log "Error for Db.exists %s:%s\n%a"
          (Repository.info repository)
          (Repository.commit_hash repository)
          Fmt.exn exn);
    -1

let record_stage_start ~stage ~job_id ~serial_id (db : Postgresql.connection) =
  Logs.debug (fun log -> log "Recording build start...");
  let job_id = Sql_util.string job_id in
  let serial_id = Sql_util.int serial_id in
  let query =
    Fmt.str
      {|
UPDATE
  benchmark_metadata
  SET
    %s = %s
    WHERE id = %s
|}
      stage job_id serial_id
  in
  try ignore (db#exec ~expect:[ Postgresql.Command_ok ] query) with
  | Postgresql.Error err ->
      Logs.err (fun log ->
          log "Database error: %s" (Postgresql.string_of_error err))
  | exn -> Logs.err (fun log -> log "Unknown error:\n%a" Fmt.exn exn)
