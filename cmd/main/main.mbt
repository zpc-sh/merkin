///|
fn main {
  let args = @env.args()
  if args.length() <= 1 {
    print_usage()
    return
  }

  let cmd = args[1]
  if cmd != "daemon" {
    print_usage()
    return
  }

  let action = value_after(args, "--action", "demo")
  let node_id = value_after(args, "--node-id", "node-1")
  let mode = parse_mode(value_after(args, "--mode", "receiver"))
  let target_ids = split_csv(value_after(args, "--targets", "local-1"))
  let oci_flags = parse_oci_flags(value_after(args, "--oci", ""), mode)

  let policy = make_policy(target_ids, has_oci_target(target_ids))
  let daemon = @daemon.DaemonNode::new(
    node_id,
    mode,
    policy,
    oci=Some(oci_flags),
  )
  attach_targets(daemon, target_ids)

  match action {
    "capabilities" => {
      let caps = daemon.capabilities()
      println("node=\{node_id}")
      println("mode=\{mode_name(mode)}")
      println("receiver=\{caps.receiver}")
      println("proxy=\{caps.proxy}")
      println("passthrough=\{caps.passthrough}")
    }
    "put" => {
      let payload = string_to_bytes(
        value_after(args, "--payload", "hello-merkin"),
      )
      let lane = parse_lane(value_after(args, "--lane", "hot"))
      let path = parse_path(value_after(args, "--path", "ingest/oci"))
      let result = daemon.handle_oci_put({
        payload,
        lane,
        event: @storage.Ingest,
        path,
        sealed_epoch: false,
      })
      println("disposition=\{result.disposition}")
      println("digest=\{result.digest.key()}")
      match result.receipt {
        Some(r) => {
          println("committed=\{r.committed_count}")
          println("quorum_met=\{r.quorum_met}")
        }
        None => println("committed=0")
      }
    }
    "sparse" => {
      let routes = parse_routes(
        value_after(args, "--routes", "alpha/doc,beta/doc"),
      )
      let tokens = parse_tokens(value_after(args, "--tokens", "alpha"))
      seed_routes(daemon, routes)
      let view = daemon.sparse_view(tokens)
      println("indexed_nodes=\{daemon.indexed_node_count()}")
      println("tokens=\{path_to_string(tokens)}")
      println("sparse_nodes=\{view.node_count()}")
      match view.root() {
        Some(key) => println("sparse_root=\{key}")
        None => println("sparse_root=none")
      }
    }
    "diff" => {
      let left_routes = parse_routes(
        value_after(args, "--left-routes", "alpha/doc"),
      )
      let right_routes = parse_routes(
        value_after(args, "--right-routes", "beta/doc"),
      )
      let left_tokens = parse_tokens(
        value_after(args, "--left-tokens", "alpha"),
      )
      let right_tokens = parse_tokens(
        value_after(args, "--right-tokens", "beta"),
      )

      seed_routes(daemon, left_routes)
      let baseline = daemon.sparse_view([])
      seed_routes(daemon, right_routes)

      let growth = daemon.diff_from_sparse(baseline, [])
      let token_diff = daemon.diff_views(left_tokens, right_tokens)
      println("growth=\{growth}")
      println("token_diff=\{token_diff}")
    }
    "conv-turn" => {
      let host = @daemon.ConversationHost::new()
      let hall = host.create_hall(
        value_after(args, "--hall", "saba"),
        value_after(args, "--policy-profile", "debate-default"),
      )
      let track = parse_conv_track(value_after(args, "--track", "program"))
      match
        host.create_thread(
          hall.hall_id,
          value_after(args, "--topic", "ai-debate"),
          track,
        ) {
        Some(thread) => {
          let envelope : @daemon.LengthEnvelope = {
            input_len_min: parse_uint(value_after(args, "--input-min", "1"), 1U),
            input_len_max: parse_uint(
              value_after(args, "--input-max", "12000"),
              12000U,
            ),
            output_len_min: parse_uint(
              value_after(args, "--output-min", "1"),
              1U,
            ),
            output_len_max: parse_uint(
              value_after(args, "--output-max", "24000"),
              24000U,
            ),
          }
          let outcome = host.append_turn(thread.thread_id, {
            actor_overlay: value_after(args, "--overlay", "chatgpt"),
            actor_role: parse_actor_role(
              value_after(args, "--actor-role", "ai"),
            ),
            content: value_after(args, "--content", "debate turn"),
            length_envelope: envelope,
            idempotency_key: value_after(args, "--idempotency-key", ""),
          })
          println("accepted=\{outcome.accepted}")
          println("issues=\{outcome.issues.length()}")
          match outcome.turn_id {
            Some(turn_id) => println("turn_id=\{turn_id}")
            None => println("turn_id=none")
          }
          match outcome.turn_seq {
            Some(turn_seq) => println("turn_seq=\{turn_seq}")
            None => println("turn_seq=none")
          }
          match outcome.checkpoint_id {
            Some(checkpoint_id) => println("checkpoint_id=\{checkpoint_id}")
            None => println("checkpoint_id=none")
          }
          for issue in outcome.issues {
            println("issue=\{issue.code}:\{issue.message}")
          }
          for addr in outcome.canonical_addresses {
            println("address=\{addr}")
          }
        }
        None => println("thread=create_failed")
      }
    }
    "conv-replay" => {
      let host = @daemon.ConversationHost::new()
      let hall = host.create_hall(
        value_after(args, "--hall", "saba"),
        value_after(args, "--policy-profile", "debate-default"),
      )
      let track = parse_conv_track(value_after(args, "--track", "program"))
      match
        host.create_thread(
          hall.hall_id,
          value_after(args, "--topic", "ai-debate"),
          track,
        ) {
        Some(thread) => {
          let envelope : @daemon.LengthEnvelope = {
            input_len_min: parse_uint(value_after(args, "--input-min", "1"), 1U),
            input_len_max: parse_uint(
              value_after(args, "--input-max", "12000"),
              12000U,
            ),
            output_len_min: parse_uint(
              value_after(args, "--output-min", "1"),
              1U,
            ),
            output_len_max: parse_uint(
              value_after(args, "--output-max", "24000"),
              24000U,
            ),
          }
          let first = host.append_turn(thread.thread_id, {
            actor_overlay: value_after(args, "--overlay", "chatgpt"),
            actor_role: parse_actor_role(
              value_after(args, "--actor-role", "ai"),
            ),
            content: value_after(args, "--content", "debate turn"),
            length_envelope: envelope,
            idempotency_key: "seed-1",
          })
          println("seed_accepted=\{first.accepted}")

          if parse_bool(
              value_after(args, "--seed-non-replayable", "false"),
              false,
            ) {
            ignore(
              host.append_turn(thread.thread_id, {
                actor_overlay: value_after(args, "--overlay", "chatgpt"),
                actor_role: parse_actor_role(
                  value_after(args, "--actor-role", "ai"),
                ),
                content: "non-replayable-seed",
                length_envelope: {
                  input_len_min: 1U,
                  input_len_max: 200U,
                  output_len_min: 1U,
                  output_len_max: 2U,
                },
                idempotency_key: "seed-2",
              }),
            )
          }

          let to_seq_value = value_after(args, "--to-seq", "")
          let to_seq = if to_seq_value == "" {
            None
          } else {
            Some(parse_uint(to_seq_value, 1U))
          }
          let replay = host.replay(thread.thread_id, {
            from_seq: parse_uint(value_after(args, "--from-seq", "1"), 1U),
            to_seq,
            length_guard_enforced: parse_bool(
              value_after(args, "--enforce-length", "true"),
              true,
            ),
          })
          println("replay_ok=\{replay.ok}")
          println("replayed=\{replay.replayed_count}")
          println("non_replayable=\{replay.non_replayable_count}")
          println("issues=\{replay.issues.length()}")
          for issue in replay.issues {
            println("issue=\{issue.code}:\{issue.message}")
          }
        }
        None => println("thread=create_failed")
      }
    }
    "conv-embed" => {
      let host = @daemon.ConversationHost::new()
      let hall = host.create_hall(
        value_after(args, "--hall", "saba"),
        value_after(args, "--policy-profile", "debate-default"),
      )
      let track = parse_conv_track(value_after(args, "--track", "program"))
      match
        host.create_thread(
          hall.hall_id,
          value_after(args, "--topic", "ai-debate"),
          track,
        ) {
        Some(thread) => {
          ignore(
            host.append_turn(
              thread.thread_id,
              @daemon.TurnRequest::default(
                value_after(args, "--content", "seed turn"),
              ),
            ),
          )
          let action = parse_embedding_action(
            value_after(args, "--embedding-action", "observe"),
          )
          match
            host.record_embedding(
              thread.thread_id,
              value_after(args, "--file-ref", "docs/sample.bin"),
              value_after(args, "--file-type", "bin"),
              value_after(args, "--mime-type", "application/octet-stream"),
              parse_bool(value_after(args, "--embedding-found", "true"), true),
              parse_uint(value_after(args, "--embedding-count", "1"), 1U),
              action,
              parse_bool(
                value_after(args, "--embedding-ephemeral", "true"),
                true,
              ),
              parse_uint(value_after(args, "--purge-after-turns", "1"), 1U),
              value_after(args, "--embedding-note", "runtime scan"),
            ) {
            Some(record) => {
              println("embedding_recorded=true")
              println("record_id=\{record.record_id}")
              println("thread_id=\{record.thread_id}")
              println("file_ref=\{record.file_ref}")
              println("file_type=\{record.file_type}")
              println("found=\{record.found}")
              println("count=\{record.count}")
              println("ephemeral=\{record.ephemeral}")
              println("purge_after_turns=\{record.purge_after_turns}")
            }
            None => println("embedding_recorded=false")
          }
        }
        None => println("thread=create_failed")
      }
    }
    "conv-embed-purge" => {
      let host = @daemon.ConversationHost::new()
      let hall = host.create_hall(
        value_after(args, "--hall", "saba"),
        value_after(args, "--policy-profile", "debate-default"),
      )
      let track = parse_conv_track(value_after(args, "--track", "program"))
      match
        host.create_thread(
          hall.hall_id,
          value_after(args, "--topic", "ai-debate"),
          track,
        ) {
        Some(thread) => {
          ignore(
            host.append_turn(
              thread.thread_id,
              @daemon.TurnRequest::default("turn-1"),
            ),
          )
          ignore(
            host.record_embedding(
              thread.thread_id,
              value_after(args, "--file-ref", "docs/sample.bin"),
              value_after(args, "--file-type", "bin"),
              value_after(args, "--mime-type", "application/octet-stream"),
              true,
              1U,
              parse_embedding_action(
                value_after(args, "--embedding-action", "flip-aot"),
              ),
              true,
              parse_uint(value_after(args, "--purge-after-turns", "1"), 1U),
              "ephemeral embedding marker",
            ),
          )
          ignore(
            host.append_turn(
              thread.thread_id,
              @daemon.TurnRequest::default("turn-2"),
            ),
          )
          let before = host.embedding_timeline(thread.thread_id)
          let purged = host.purge_embedding_records(
            thread.thread_id,
            parse_uint(value_after(args, "--current-turn-seq", "2"), 2U),
          )
          let after = host.embedding_timeline(thread.thread_id)
          println("before=\{before.length()}")
          println("purged=\{purged}")
          println("after=\{after.length()}")
        }
        None => println("thread=create_failed")
      }
    }
    _ => {
      // demo: put then read
      let payload = b"demo-payload"
      let put = daemon.handle_oci_put(@daemon.OciPutRequest::default(payload))
      println("demo disposition=\{put.disposition}")
      println("demo digest=\{put.digest.key()}")
      match daemon.handle_get(put.digest) {
        Some(bytes) => println("demo get=\{bytes.length()} bytes")
        None => println("demo get=miss")
      }
    }
  }
}

///|
fn print_usage() -> Unit {
  println("Usage:")
  println("  moon run cmd/main -- daemon --action capabilities --mode receiver")
  println(
    "  moon run cmd/main -- daemon --action put --payload hello --mode hybrid --targets local-1,oci-1",
  )
  println(
    "  moon run cmd/main -- daemon --action sparse --routes alpha/doc,beta/doc --tokens alpha",
  )
  println(
    "  moon run cmd/main -- daemon --action diff --left-routes alpha/doc --right-routes beta/doc",
  )
  println(
    "  moon run cmd/main -- daemon --action conv-turn --hall saba --topic debate --content \"Opening statement\"",
  )
  println(
    "  moon run cmd/main -- daemon --action conv-replay --seed-non-replayable true --enforce-length true",
  )
  println(
    "  moon run cmd/main -- daemon --action conv-embed --file-ref docs/sample.bin --embedding-action flip-aot",
  )
  println(
    "  moon run cmd/main -- daemon --action conv-embed-purge --purge-after-turns 1 --current-turn-seq 2",
  )
  println("Flags:")
  println(
    "  --action capabilities|put|sparse|diff|conv-turn|conv-replay|conv-embed|conv-embed-purge|demo",
  )
  println("  --mode receiver|proxy|passthrough|hybrid")
  println("  --node-id <id>")
  println("  --targets <comma-separated ids>")
  println("  --oci receiver,proxy,passthrough (optional override)")
  println("  --payload <string> (for put)")
  println("  --lane critical|hot|warm|cold|archive (for put)")
  println("  --path a/b/c (for put)")
  println("  --routes a/b,c/d (for sparse)")
  println("  --tokens a,b (for sparse)")
  println("  --left-routes a/b (for diff)")
  println("  --right-routes c/d (for diff)")
  println("  --left-tokens a,b (for diff)")
  println("  --right-tokens a,b (for diff)")
  println("  --hall <name> (for conv-*)")
  println("  --policy-profile <name> (for conv-*)")
  println("  --topic <text> (for conv-*)")
  println("  --track program|git (for conv-*)")
  println("  --overlay <name> (for conv-*)")
  println("  --actor-role ai|human|system (for conv-*)")
  println("  --content <text> (for conv-*)")
  println("  --idempotency-key <text> (for conv-turn)")
  println("  --input-min <uint> (for conv-*)")
  println("  --input-max <uint> (for conv-*)")
  println("  --output-min <uint> (for conv-*)")
  println("  --output-max <uint> (for conv-*)")
  println("  --from-seq <uint> (for conv-replay)")
  println("  --to-seq <uint> (for conv-replay)")
  println("  --enforce-length true|false (for conv-replay)")
  println("  --seed-non-replayable true|false (for conv-replay)")
  println("  --file-ref <path> (for conv-embed*)")
  println("  --file-type <type> (for conv-embed*)")
  println("  --mime-type <mime> (for conv-embed*)")
  println("  --embedding-found true|false (for conv-embed)")
  println("  --embedding-count <uint> (for conv-embed)")
  println("  --embedding-action observe|flip-aot|purge (for conv-embed*)")
  println("  --embedding-ephemeral true|false (for conv-embed)")
  println("  --purge-after-turns <uint> (for conv-embed*)")
  println("  --embedding-note <text> (for conv-embed)")
  println("  --current-turn-seq <uint> (for conv-embed-purge)")
}

///|
fn value_after(
  args : Array[String],
  flag : String,
  fallback : String,
) -> String {
  for i = 0; i < args.length(); i = i + 1 {
    if args[i] == flag && i + 1 < args.length() {
      return args[i + 1]
    }
  }
  fallback
}

///|
fn parse_mode(value : String) -> @daemon.DaemonMode {
  match value {
    "receiver" => @daemon.Receiver
    "proxy" => @daemon.Proxy
    "passthrough" => @daemon.PassThrough
    "hybrid" => @daemon.Hybrid
    _ => @daemon.Receiver
  }
}

///|
fn parse_conv_track(value : String) -> @daemon.ConversationTrack {
  match value {
    "git" => @daemon.Git
    _ => @daemon.Program
  }
}

///|
fn parse_actor_role(value : String) -> @daemon.ConversationActorRole {
  match value {
    "human" => @daemon.Human
    "system" => @daemon.System
    _ => @daemon.Ai
  }
}

///|
fn parse_embedding_action(
  value : String,
) -> @daemon.ConversationEmbeddingAction {
  match value {
    "flip-aot" => @daemon.FlipAot
    "purge" => @daemon.Purge
    _ => @daemon.Observe
  }
}

///|
fn mode_name(mode : @daemon.DaemonMode) -> String {
  match mode {
    @daemon.Receiver => "receiver"
    @daemon.Proxy => "proxy"
    @daemon.PassThrough => "passthrough"
    @daemon.Hybrid => "hybrid"
  }
}

///|
fn parse_lane(value : String) -> @storage.ReplicationLane {
  match value {
    "critical" => @storage.Critical
    "hot" => @storage.Hot
    "warm" => @storage.Warm
    "cold" => @storage.Cold
    "archive" => @storage.ArchiveLane
    _ => @storage.Hot
  }
}

///|
fn parse_bool(value : String, fallback : Bool) -> Bool {
  match value {
    "true" => true
    "false" => false
    _ => fallback
  }
}

///|
fn parse_uint(value : String, fallback : UInt) -> UInt {
  if value == "" {
    return fallback
  }
  let mut out : UInt = 0U
  for ch in value {
    let code = ch.to_uint()
    if code < 48U || code > 57U {
      return fallback
    }
    out = out * 10U + (code - 48U)
  }
  out
}

///|
fn parse_path(value : String) -> Array[String] {
  let out : Array[String] = []
  let mut cur = StringBuilder::new(size_hint=32)
  for ch in value {
    if ch == '/' {
      let s = cur.to_string()
      if s != "" {
        out.push(s)
      }
      cur = StringBuilder::new(size_hint=32)
    } else {
      cur.write_char(ch)
    }
  }
  let s = cur.to_string()
  if s != "" {
    out.push(s)
  }
  if out.length() == 0 {
    ["ingest", "oci"]
  } else {
    out
  }
}

///|
fn split_csv(value : String) -> Array[String] {
  let out = split_csv_raw(value)
  if out.length() == 0 {
    ["local-1"]
  } else {
    out
  }
}

///|
fn split_csv_raw(value : String) -> Array[String] {
  let out : Array[String] = []
  let mut cur = StringBuilder::new(size_hint=32)
  for ch in value {
    if ch == ',' {
      let s = cur.to_string()
      if s != "" {
        out.push(s)
      }
      cur = StringBuilder::new(size_hint=32)
    } else {
      cur.write_char(ch)
    }
  }
  let s = cur.to_string()
  if s != "" {
    out.push(s)
  }
  out
}

///|
fn parse_tokens(value : String) -> Array[String] {
  split_csv_raw(value)
}

///|
fn parse_routes(csv : String) -> Array[Array[String]] {
  let routes : Array[Array[String]] = []
  for raw in split_csv_raw(csv) {
    routes.push(parse_path(raw))
  }
  if routes.length() == 0 {
    [parse_path("ingest/oci")]
  } else {
    routes
  }
}

///|
fn path_to_string(path : Array[String]) -> String {
  let out = StringBuilder::new(size_hint=64)
  for i = 0; i < path.length(); i = i + 1 {
    if i > 0 {
      out.write_char('/')
    }
    out.write_string(path[i])
  }
  out.to_string()
}

///|
fn seed_routes(
  daemon : @daemon.DaemonNode,
  routes : Array[Array[String]],
) -> Unit {
  for i = 0; i < routes.length(); i = i + 1 {
    let path = routes[i]
    let payload = string_to_bytes(
      "route-" + i.to_string() + ":" + path_to_string(path),
    )
    ignore(
      daemon.handle_oci_put({
        payload,
        lane: @storage.Hot,
        event: @storage.Ingest,
        path,
        sealed_epoch: false,
      }),
    )
  }
}

///|
fn parse_oci_flags(
  csv : String,
  mode : @daemon.DaemonMode,
) -> @daemon.OciFacility {
  if csv == "" {
    return @daemon.OciFacility::from_mode(mode)
  }
  let parts = split_csv_raw(csv)
  let mut receiver = false
  let mut proxy = false
  let mut passthrough = false
  for part in parts {
    match part {
      "receiver" => receiver = true
      "proxy" => proxy = true
      "passthrough" => passthrough = true
      _ => ()
    }
  }
  { receiver, proxy, passthrough }
}

///|
fn has_oci_target(target_ids : Array[String]) -> Bool {
  for id in target_ids {
    if starts_with(id, "oci-") {
      return true
    }
  }
  false
}

///|
fn starts_with(value : String, prefix : String) -> Bool {
  if prefix.length() > value.length() {
    return false
  }
  for i = 0; i < prefix.length(); i = i + 1 {
    if value[i] != prefix[i] {
      return false
    }
  }
  true
}

///|
fn make_policy(
  target_ids : Array[String],
  oci_enabled : Bool,
) -> @storage.ReplicationPolicy {
  let targets : Array[@storage.TargetRule] = []
  for id in target_ids {
    let role = if starts_with(id, "oci-") {
      @storage.Oci
    } else {
      @storage.Local
    }
    targets.push({
      target_id: id,
      role,
      lanes: [@storage.Critical, @storage.Hot, @storage.Warm, @storage.Cold],
      min_availability: @storage.Online,
      write_mode: @storage.SyncQuorum,
      pull_on_miss: true,
    })
  }

  let oci : @storage.OciPolicy = if oci_enabled {
    {
      enabled: true,
      repository: "registry.example.com/merkin/default",
      artifact_media_type: "application/vnd.merkin.artifact.v1+octet-stream",
      tag_mode: @storage.LatestTag,
    }
  } else {
    @storage.OciPolicy::disabled()
  }

  @storage.ReplicationPolicy::new(
    1U,
    1UL,
    1U,
    1U,
    @storage.IdempotencyPolicy::default(),
    @storage.BackpressurePolicy::default(),
    oci,
    targets,
    [],
  )
}

///|
fn attach_targets(
  daemon : @daemon.DaemonNode,
  target_ids : Array[String],
) -> Unit {
  let oci_registry = @storage.InMemoryOciRegistry::new()
  for id in target_ids {
    if starts_with(id, "oci-") {
      let oci = @storage.OciCasNode::new(
        id,
        "registry.example.com/merkin/\{id}",
        oci_registry,
      )
      daemon.add_store(oci.as_store_node())
    } else {
      let local_node = @storage.ArtifactCasNode::new(id, @storage.Local)
      daemon.add_store(local_node.as_store_node())
    }
  }
}

///|
fn string_to_bytes(s : String) -> Bytes {
  let mut total = 0
  for _ch in s {
    total = total + 4
  }
  let buf = FixedArray::make(total, b'\x00')
  let mut pos = 0
  for ch in s {
    let code = ch.to_uint()
    buf[pos] = ((code >> 24) & 0xFFU).to_byte()
    buf[pos + 1] = ((code >> 16) & 0xFFU).to_byte()
    buf[pos + 2] = ((code >> 8) & 0xFFU).to_byte()
    buf[pos + 3] = (code & 0xFFU).to_byte()
    pos = pos + 4
  }
  Bytes::from_array(buf)
}
