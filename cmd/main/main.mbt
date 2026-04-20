///|
fn main {
  let args = @env.args()
  if args.length() <= 1 {
    print_usage()
    return
  }

  let cmd = args[1]

  // Merkin CLI commands
  match cmd {
    "ratio" => {
      run_ratio_command(args)
      return
    }
    "genius" => {
      run_genius_command(args)
      return
    }
    "init" => {
      run_ratio_alias_command(args)
      return
    }
    "loci" => {
      run_ratio_alias_command(args)
      return
    }
    "app" => {
      run_ratio_alias_command(args)
      return
    }
    "enter" => {
      run_genius_alias_command(args)
      return
    }
    "sign" => {
      run_genius_alias_command(args)
      return
    }
    "trail" => {
      run_genius_alias_command(args)
      return
    }
    "where" => {
      run_genius_alias_command(args)
      return
    }
    "residue" => {
      run_genius_alias_command(args)
      return
    }
    "status" => {
      run_ratio_alias_command(args)
      return
    }
    "pack" => {
      run_ratio_alias_command(args)
      return
    }
    "daemon" => () // fall through to existing daemon handling
    _ => {
      print_usage()
      return
    }
  }

  // Daemon subcommand handling (existing)
  let action = resolve_action(args)
  if action == "help" {
    print_usage()
    return
  }
  if action_is_bridge_only(action) {
    run_bridge_action(args, action)
    return
  }
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
    "conv-plan" => {
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
          ignore(
            host.record_embedding(
              thread.thread_id,
              value_after(args, "--file-ref", "docs/sample.bin"),
              value_after(args, "--file-type", "bin"),
              value_after(args, "--mime-type", "application/octet-stream"),
              parse_bool(value_after(args, "--embedding-found", "true"), true),
              parse_uint(value_after(args, "--embedding-count", "1"), 1U),
              parse_embedding_action(
                value_after(args, "--embedding-action", "observe"),
              ),
              parse_bool(
                value_after(args, "--embedding-ephemeral", "true"),
                true,
              ),
              parse_uint(value_after(args, "--purge-after-turns", "1"), 1U),
              value_after(args, "--embedding-note", "runtime scan"),
            ),
          )
          if parse_bool(
              value_after(args, "--seed-second-embedding", "false"),
              false,
            ) {
            ignore(
              host.record_embedding(
                thread.thread_id,
                value_after(args, "--second-file-ref", "docs/second.bin"),
                value_after(args, "--second-file-type", "bin"),
                value_after(
                  args, "--second-mime-type", "application/octet-stream",
                ),
                parse_bool(
                  value_after(args, "--second-embedding-found", "false"),
                  false,
                ),
                parse_uint(
                  value_after(args, "--second-embedding-count", "0"),
                  0U,
                ),
                parse_embedding_action(
                  value_after(args, "--second-embedding-action", "observe"),
                ),
                parse_bool(
                  value_after(args, "--second-embedding-ephemeral", "true"),
                  true,
                ),
                parse_uint(
                  value_after(args, "--second-purge-after-turns", "1"),
                  1U,
                ),
                value_after(
                  args, "--second-embedding-note", "second runtime scan",
                ),
              ),
            )
          }
          match
            host.emit_embedding_plan(
              thread.thread_id,
              value_after(args, "--plan-overlay", "chatgpt"),
              value_after(args, "--plan-peer", "claude"),
              value_after(args, "--plan-authority", "substrate://loc/chatgpt"),
              value_after(args, "--plan-generator", "daemon.conversation"),
              value_after(
                args, "--plan-note", "conversation embedding timeline",
              ),
            ) {
            Some(wire) => {
              println("plan_emitted=true")
              println(wire)
            }
            None => println("plan_emitted=false")
          }
        }
        None => println("thread=create_failed")
      }
    }
    "yata-topology" =>
      run_yata_topology(
        parse_uint(value_after(args, "--yata-branch-factor", "3"), 3U),
        parse_uint(value_after(args, "--yata-detached-depth", "2"), 2U),
        parse_uint(value_after(args, "--yata-max-children", "2"), 2U),
        parse_uint(value_after(args, "--yata-max-depth", "8"), 8U),
      )
    "yata-wasm-plan" => run_yata_wasm_plan(args)
    "yata-triad-contract" => run_yata_triad_contract(args)
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
  println("  merkin <group|command> [args] [flags]")
  println("")
  println("Canonical command groups:")
  println(
    "  merkin ratio <command> ...                         Repository/root surface",
  )
  println(
    "  merkin genius <command> ...                        AI-only inhabitation surface",
  )
  println("")
  print_ratio_usage()
  println("")
  print_genius_usage()
  println("")
  println("Compatibility aliases:")
  println("  init     → ratio init")
  println("  loci     → ratio loci")
  println("  app      → ratio app")
  println("  status   → ratio status")
  println("  pack     → ratio pack")
  println("  enter    → genius enter")
  println("  sign     → genius sign")
  println("  trail    → genius trail")
  println("  where    → genius where")
  println("  residue  → genius residue")
  println("")
  println("Daemon Commands:")
  println("  moon run cmd/main -- daemon <category> <command> [flags]")
  println("")
  println("Categories:")
  println("  oci: capabilities | put")
  println("  tree: sparse | diff")
  println("  conv: turn | replay | embed | embed-purge")
  println("  yata: topology | wasm-plan | triad-contract")
  println("  cognitive: compile | distributed | measure")
  println("  adapter: validate")
  println("")
  println("Categorical examples:")
  println("  moon run cmd/main -- daemon oci capabilities --mode receiver")
  println(
    "  moon run cmd/main -- daemon oci put --payload hello --mode hybrid --targets local-1,oci-1",
  )
  println(
    "  moon run cmd/main -- daemon tree sparse --routes alpha/doc,beta/doc --tokens alpha",
  )
  println(
    "  moon run cmd/main -- daemon tree diff --left-routes alpha/doc --right-routes beta/doc",
  )
  println(
    "  moon run cmd/main -- daemon conv turn --hall saba --topic debate --content \"Opening statement\"",
  )
  println(
    "  moon run cmd/main -- daemon conv replay --seed-non-replayable true --enforce-length true",
  )
  println(
    "  moon run cmd/main -- daemon conv embed --file-ref docs/sample.bin --embedding-action flip-aot",
  )
  println(
    "  moon run cmd/main -- daemon conv embed-purge --purge-after-turns 1 --current-turn-seq 2",
  )
  println(
    "  moon run cmd/main -- daemon yata topology --yata-branch-factor 5 --yata-max-children 3",
  )
  println(
    "  moon run cmd/main -- daemon yata wasm-plan --routes alpha/doc,beta/doc --tokens alpha --drift-peers mu:abc,muyata:def",
  )
  println(
    "  moon run cmd/main -- daemon yata triad-contract --routes alpha/doc,beta/doc --tokens alpha --drift-peers mu:abc,lang:def --merkin-head aaa --mu-head bbb --lang-head ccc",
  )
  println(
    "  moon run cmd/main -- daemon cognitive compile --mode markup --emit-distributed true",
  )
  println(
    "  moon run cmd/main -- daemon cognitive distributed --compiler-out-dir _build/cognitive/v0.3/latest",
  )
  println(
    "  moon run cmd/main -- daemon cognitive measure --summary-file _build/cognitive/v0.3/latest/summary.txt",
  )
  println(
    "  moon run cmd/main -- daemon adapter validate --action status --file /tmp/adapter.json",
  )
  println("")
  println("Legacy --action examples:")
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
  println(
    "  moon run cmd/main -- daemon --action conv-plan --file-ref docs/sample.bin --embedding-action observe",
  )
  println(
    "  moon run cmd/main -- daemon --action yata-topology --yata-branch-factor 5 --yata-max-children 3",
  )
  println(
    "  moon run cmd/main -- daemon --action yata-wasm-plan --routes alpha/doc,beta/doc --tokens alpha --drift-peers mu:abc,muyata:def",
  )
  println(
    "  moon run cmd/main -- daemon --action yata-triad-contract --routes alpha/doc,beta/doc --tokens alpha --drift-peers mu:abc,lang:def --merkin-head aaa --mu-head bbb --lang-head ccc",
  )
  println("Flags:")
  println(
    "  --action capabilities|put|sparse|diff|conv-turn|conv-replay|conv-embed|conv-embed-purge|conv-plan|yata-topology|yata-wasm-plan|yata-triad-contract|demo",
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
  println("  --plan-overlay <name> (for conv-plan)")
  println("  --plan-peer <name> (for conv-plan)")
  println("  --plan-authority <uri> (for conv-plan)")
  println("  --plan-generator <name> (for conv-plan)")
  println("  --plan-note <text> (for conv-plan)")
  println("  --seed-second-embedding true|false (for conv-plan)")
  println("  --second-file-ref <path> (for conv-plan)")
  println("  --second-file-type <type> (for conv-plan)")
  println("  --second-mime-type <mime> (for conv-plan)")
  println("  --second-embedding-found true|false (for conv-plan)")
  println("  --second-embedding-count <uint> (for conv-plan)")
  println("  --second-embedding-action observe|flip-aot|purge (for conv-plan)")
  println("  --second-embedding-ephemeral true|false (for conv-plan)")
  println("  --second-purge-after-turns <uint> (for conv-plan)")
  println("  --second-embedding-note <text> (for conv-plan)")
  println("  --yata-branch-factor <uint> (for yata-topology)")
  println("  --yata-detached-depth <uint> (for yata-topology)")
  println("  --yata-max-children <uint> (for yata-topology)")
  println("  --yata-max-depth <uint> (for yata-topology)")
  println(
    "  --drift-peers <peer-a,peer-b> (for yata-wasm-plan/yata-triad-contract)",
  )
  println("  --seal true|false (for yata-wasm-plan/yata-triad-contract)")
  println("  --merkin-head <git-head> (for yata-triad-contract)")
  println("  --mu-head <git-head> (for yata-triad-contract)")
  println("  --lang-head <git-head> (for yata-triad-contract)")
  println("  --merkin-branch <branch> (for yata-triad-contract)")
  println("  --mu-branch <branch> (for yata-triad-contract)")
  println("  --lang-branch <branch> (for yata-triad-contract)")
  println("  --wasm-exports <csv> (for yata-triad-contract)")
  println("  --generated-at-utc <rfc3339> (for yata-triad-contract)")
  println("  --contract-version <text> (for yata-triad-contract)")
  println("  --emit-distributed true|false (for cognitive compile bridge)")
  println("  --distributed-out-dir <dir> (for cognitive compile bridge)")
  println("  --distributed-cluster-name <name> (for cognitive compile bridge)")
  println(
    "  --distributed-shards <uint> (for cognitive compile/distributed bridge)",
  )
  println(
    "  --distributed-replicas <uint> (for cognitive compile/distributed bridge)",
  )
  println(
    "  --distributed-max-inflight-per-shard <uint> (for cognitive compile/distributed bridge)",
  )
  println(
    "  --distributed-regions <csv> (for cognitive compile/distributed bridge)",
  )
  println("  --summary-file <path> (for cognitive distributed/measure bridge)")
  println("  --compiler-out-dir <dir> (for cognitive distributed bridge)")
  println("  --coord-minutes-per-hole <uint> (for cognitive measure bridge)")
  println(
    "  --automation-overhead-minutes <uint> (for cognitive measure bridge)",
  )
  println("  --fix-minutes-low <uint> (for cognitive measure bridge)")
  println("  --fix-minutes-high <uint> (for cognitive measure bridge)")
  println(
    "  --active-delegation-coverage <0..1> (for cognitive measure bridge)",
  )
  println("  --action submit|status|cancel (for adapter validate bridge)")
  println("  --file <path> (for adapter validate bridge)")
  println("  --last-line true|false (for adapter validate bridge)")
  println("  --full true|false (for adapter validate bridge)")
}

///|
fn resolve_action(args : Array[String]) -> String {
  if args.length() > 2 {
    let primary = args[2]
    if primary != "--action" {
      return parse_categorical_action(args)
    }
  }
  let explicit = value_after(args, "--action", "")
  if explicit != "" {
    normalize_direct_action(explicit)
  } else {
    "demo"
  }
}

///|
fn parse_categorical_action(args : Array[String]) -> String {
  if args.length() <= 2 {
    return "demo"
  }
  let primary = args[2]
  let secondary = if args.length() > 3 { args[3] } else { "" }
  match primary {
    "help" => "help"
    "demo" => "demo"
    "oci" => map_oci_action(secondary)
    "tree" => map_tree_action(secondary)
    "conv" => map_conv_action(secondary)
    "yata" => map_yata_action(secondary)
    "cognitive" => map_cognitive_action(secondary)
    "adapter" => map_adapter_action(secondary)
    _ => normalize_direct_action(primary)
  }
}

///|
fn map_oci_action(value : String) -> String {
  match value {
    "put" => "put"
    "capabilities" => "capabilities"
    _ => "capabilities"
  }
}

///|
fn map_tree_action(value : String) -> String {
  match value {
    "diff" => "diff"
    "sparse" => "sparse"
    _ => "sparse"
  }
}

///|
fn map_conv_action(value : String) -> String {
  match value {
    "turn" => "conv-turn"
    "replay" => "conv-replay"
    "embed" => "conv-embed"
    "embed-purge" => "conv-embed-purge"
    _ => "conv-turn"
  }
}

///|
fn map_yata_action(value : String) -> String {
  match value {
    "topology" => "yata-topology"
    "wasm-plan" => "yata-wasm-plan"
    "triad-contract" => "yata-triad-contract"
    _ => "yata-topology"
  }
}

///|
fn map_cognitive_action(value : String) -> String {
  match value {
    "compile" => "cognitive-compile"
    "distributed" => "cognitive-distributed"
    "measure" => "cognitive-measure"
    _ => "cognitive-compile"
  }
}

///|
fn map_adapter_action(value : String) -> String {
  match value {
    "validate" => "adapter-validate"
    _ => "adapter-validate"
  }
}

///|
fn normalize_direct_action(value : String) -> String {
  match value {
    "capabilities" => "capabilities"
    "put" => "put"
    "sparse" => "sparse"
    "diff" => "diff"
    "conv-turn" => "conv-turn"
    "conv-replay" => "conv-replay"
    "conv-embed" => "conv-embed"
    "conv-embed-purge" => "conv-embed-purge"
    "yata-topology" => "yata-topology"
    "yata-wasm-plan" => "yata-wasm-plan"
    "yata-triad-contract" => "yata-triad-contract"
    "cognitive-compile" => "cognitive-compile"
    "cognitive-distributed" => "cognitive-distributed"
    "cognitive-measure" => "cognitive-measure"
    "adapter-validate" => "adapter-validate"
    "turn" => "conv-turn"
    "replay" => "conv-replay"
    "embed" => "conv-embed"
    "embed-purge" => "conv-embed-purge"
    "topology" => "yata-topology"
    "wasm-plan" => "yata-wasm-plan"
    "triad-contract" => "yata-triad-contract"
    "compile" => "cognitive-compile"
    "distributed" => "cognitive-distributed"
    "measure" => "cognitive-measure"
    "validate" => "adapter-validate"
    _ => "demo"
  }
}

///|
fn action_is_bridge_only(action : String) -> Bool {
  match action {
    "cognitive-compile" => true
    "cognitive-distributed" => true
    "cognitive-measure" => true
    "adapter-validate" => true
    _ => false
  }
}

///|
fn has_flag(args : Array[String], flag : String) -> Bool {
  for arg in args {
    if arg == flag {
      return true
    }
  }
  false
}

///|
fn bool_flag(args : Array[String], flag : String, default : Bool) -> Bool {
  let raw = value_after(args, flag, "")
  if raw != "" {
    return parse_bool(raw, default)
  }
  if has_flag(args, flag) {
    return true
  }
  default
}

///|
fn run_bridge_action(args : Array[String], action : String) -> Unit {
  match action {
    "cognitive-compile" => {
      let mode = value_after(args, "--mode", "markup")
      let out_dir = value_after(
        args, "--out-dir", "_build/cognitive/v0.3/latest",
      )
      let pipeline_out = value_after(args, "--pipeline-out-dir", "")
      let skip_pipeline = bool_flag(args, "--skip-pipeline", false)
      let emit_distributed = bool_flag(args, "--emit-distributed", false)
      let distributed_shards = value_after(args, "--distributed-shards", "16")
      let distributed_replicas = value_after(
        args, "--distributed-replicas", "2",
      )
      let distributed_max_inflight = value_after(
        args, "--distributed-max-inflight-per-shard", "64",
      )
      let distributed_regions = value_after(
        args, "--distributed-regions", "us-west1,us-east1",
      )
      let mut cmd = "tools/cognitive-semantic-compile-v0_3.sh --mode " +
        mode +
        " --out-dir " +
        out_dir
      if pipeline_out != "" {
        cmd = cmd + " --pipeline-out-dir " + pipeline_out
      }
      if skip_pipeline {
        cmd = cmd + " --skip-pipeline"
      }
      if emit_distributed {
        cmd = cmd +
          " --emit-distributed --distributed-shards " +
          distributed_shards +
          " --distributed-replicas " +
          distributed_replicas +
          " --distributed-max-inflight-per-shard " +
          distributed_max_inflight +
          " --distributed-regions " +
          distributed_regions
      }
      println("status=bridge_only")
      println("category=cognitive")
      println("command=compile")
      println("tool=tools/cognitive-semantic-compile-v0_3.sh")
      println("bridge_command=\{cmd}")
      println(
        "note=Run the bridge_command in shell; this CLI mode is orchestration-first for now.",
      )
    }
    "cognitive-distributed" => {
      let compiler_out_dir = value_after(
        args, "--compiler-out-dir", "_build/cognitive/v0.3/latest",
      )
      let summary_file = value_after(args, "--summary-file", "")
      let shards = value_after(
        args,
        "--distributed-shards",
        value_after(args, "--shards", "16"),
      )
      let replicas = value_after(
        args,
        "--distributed-replicas",
        value_after(args, "--replicas", "2"),
      )
      let max_inflight = value_after(
        args,
        "--distributed-max-inflight-per-shard",
        value_after(args, "--max-inflight-per-shard", "64"),
      )
      let regions = value_after(
        args,
        "--distributed-regions",
        value_after(args, "--regions", "us-west1,us-east1"),
      )
      let out_dir = value_after(args, "--distributed-out-dir", "")
      let cluster = value_after(
        args,
        "--distributed-cluster-name",
        value_after(args, "--cluster-name", "merkin-cognitive-v0_3"),
      )
      let mut cmd = "tools/cognitive-distributed-plan-v0_3.sh --compiler-out-dir " +
        compiler_out_dir +
        " --shards " +
        shards +
        " --replicas " +
        replicas +
        " --max-inflight-per-shard " +
        max_inflight +
        " --regions " +
        regions +
        " --cluster-name " +
        cluster
      if summary_file != "" {
        cmd = cmd + " --summary-file " + summary_file
      }
      if out_dir != "" {
        cmd = cmd + " --out-dir " + out_dir
      }
      println("status=bridge_only")
      println("category=cognitive")
      println("command=distributed")
      println("tool=tools/cognitive-distributed-plan-v0_3.sh")
      println("bridge_command=\{cmd}")
      println(
        "note=Run the bridge_command in shell; this CLI mode is orchestration-first for now.",
      )
    }
    "cognitive-measure" => {
      let summary_file = value_after(
        args, "--summary-file", "_build/cognitive/v0.3/latest/summary.txt",
      )
      let out_file = value_after(args, "--out-file", "")
      let coord = value_after(args, "--coord-minutes-per-hole", "7")
      let overhead = value_after(args, "--automation-overhead-minutes", "10")
      let fix_low = value_after(args, "--fix-minutes-low", "12")
      let fix_high = value_after(args, "--fix-minutes-high", "30")
      let coverage = value_after(args, "--active-delegation-coverage", "")
      let mut cmd = "tools/cognitive-offload-measure-v0_3.sh --summary-file " +
        summary_file +
        " --coord-minutes-per-hole " +
        coord +
        " --automation-overhead-minutes " +
        overhead +
        " --fix-minutes-low " +
        fix_low +
        " --fix-minutes-high " +
        fix_high
      if out_file != "" {
        cmd = cmd + " --out-file " + out_file
      }
      if coverage != "" {
        cmd = cmd + " --active-delegation-coverage " + coverage
      }
      println("status=bridge_only")
      println("category=cognitive")
      println("command=measure")
      println("tool=tools/cognitive-offload-measure-v0_3.sh")
      println("bridge_command=\{cmd}")
      println(
        "note=Run the bridge_command in shell; this CLI mode is orchestration-first for now.",
      )
    }
    "adapter-validate" => {
      let action_value = value_after(args, "--action", "status")
      let file = value_after(args, "--file", "")
      let use_full = bool_flag(args, "--full", false)
      let mut cmd = "tools/ai-adapter-validate-v0_3.sh --action " + action_value
      if file != "" {
        cmd = cmd + " --file " + file
      }
      if use_full {
        cmd = cmd + " --full"
      } else {
        cmd = cmd + " --last-line"
      }
      println("status=bridge_only")
      println("category=adapter")
      println("command=validate")
      println("tool=tools/ai-adapter-validate-v0_3.sh")
      println("bridge_command=\{cmd}")
      println(
        "note=Run the bridge_command in shell; this CLI mode is orchestration-first for now.",
      )
    }
    _ => {
      println("status=bridge_only")
      println("error=unsupported_bridge_action")
      println("action=\{action}")
    }
  }
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
fn drift_peer_or_none(peers : Array[String], index : Int) -> String {
  if index < peers.length() {
    peers[index]
  } else {
    "none"
  }
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
fn path_to_csv(path : Array[String]) -> String {
  let out = StringBuilder::new(size_hint=64)
  for i = 0; i < path.length(); i = i + 1 {
    if i > 0 {
      out.write_char(',')
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
fn run_yata_wasm_plan(args : Array[String]) -> Unit {
  let routes = parse_routes(value_after(args, "--routes", "alpha/doc,beta/doc"))
  let tokens_csv = value_after(args, "--tokens", "alpha")
  let drift_peers = value_after(
    args, "--drift-peers", "mu:unknown,muyata:unknown",
  )
  let should_seal = parse_bool(value_after(args, "--seal", "true"), true)

  @api.reset()
  for i = 0; i < routes.length(); i = i + 1 {
    let route = routes[i]
    let route_path = path_to_string(route)
    let envelope_id = "route:\{i}:\{route_path}"
    ignore(@api.tree_ingest(envelope_id, path_to_csv(route)))
  }
  if should_seal {
    ignore(@api.tree_seal())
  }

  let drift = @api.plan_drift_commitment(tokens_csv, drift_peers)
  let wire = @api.plan_finger_wasm(tokens_csv, drift_peers)
  let raw_peers = split_csv_raw(drift_peers)
  let peer_a = drift_peer_or_none(raw_peers, 0)
  let peer_b = drift_peer_or_none(raw_peers, 1)
  let boundary_fsm = @model.BoundaryWalkerFsm::new(
      "daemon.yata.wasm-plan", "ratio://merkin/cmd/main",
    )
    .walk_scalars([("peer_a", peer_a), ("peer_b", peer_b)])
    .mark()
  let boundary_stigmergy = boundary_fsm.emit_stigmergy(
    note="daemon yata wasm-plan boundary walk",
  )
  let boundary_attention_saturated = if boundary_fsm.attention_saturated() {
    "1"
  } else {
    "0"
  }

  println("wasm_plan=true")
  println("boundary_ticks=\{boundary_fsm.attention_ticks()}")
  println("boundary_attention_score=\{boundary_fsm.attention_score()}")
  println("boundary_attention_gradient=\{boundary_fsm.attention_gradient()}")
  println("boundary_attention_saturated=\{boundary_attention_saturated}")
  println("route_count=\{routes.length()}")
  println("tokens=\{tokens_csv}")
  println("drift_peers=\{drift_peers}")
  println("drift_commitment=\{drift}")
  println(wire)
  println(boundary_stigmergy)
}

///|
fn run_yata_triad_contract(args : Array[String]) -> Unit {
  let routes = parse_routes(value_after(args, "--routes", "alpha/doc,beta/doc"))
  let tokens_csv = value_after(args, "--tokens", "alpha")
  let drift_peers = value_after(
    args, "--drift-peers", "mu:unknown,muyata:unknown",
  )
  let should_seal = parse_bool(value_after(args, "--seal", "true"), true)

  let merkin_head = value_after(args, "--merkin-head", "unknown")
  let mu_head = value_after(args, "--mu-head", "unknown")
  let lang_head = value_after(args, "--lang-head", "unknown")
  let merkin_branch = value_after(args, "--merkin-branch", "unknown")
  let mu_branch = value_after(args, "--mu-branch", "unknown")
  let lang_branch = value_after(args, "--lang-branch", "unknown")
  let wasm_exports_csv = value_after(
    args, "--wasm-exports", "plan_finger_wasm,plan_drift_commitment,triad_contract_wasm",
  )
  let generated_at_utc = value_after(args, "--generated-at-utc", "unknown")
  let contract_version = value_after(args, "--contract-version", "v0.1")

  @api.reset()
  for i = 0; i < routes.length(); i = i + 1 {
    let route = routes[i]
    let route_path = path_to_string(route)
    let envelope_id = "route:\{i}:\{route_path}"
    ignore(@api.tree_ingest(envelope_id, path_to_csv(route)))
  }
  if should_seal {
    ignore(@api.tree_seal())
  }

  let drift = @api.plan_drift_commitment(tokens_csv, drift_peers)
  let abi_status = @api.triad_abi_status(wasm_exports_csv)
  let contract = @api.triad_contract_wasm(
    tokens_csv, drift_peers, merkin_head, mu_head, lang_head, merkin_branch, mu_branch,
    lang_branch, wasm_exports_csv, generated_at_utc, contract_version,
  )

  println("triad_contract=true")
  println("route_count=\{routes.length()}")
  println("tokens=\{tokens_csv}")
  println("drift_peers=\{drift_peers}")
  println("drift_commitment=\{drift}")
  println("abi_status=\{abi_status}")
  println(contract)
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
fn run_yata_topology(
  branch_factor : UInt,
  detached_depth : UInt,
  max_children : UInt,
  max_depth : UInt,
) -> Unit {
  let contract = @model.YataContract::new("CliTopology", [], [], 0U)
  let root = @model.YataHole::new("cli/root.md", contract, [], [], [])
  let mut graph = @model.YataGraph::new().add(root)

  let mut i : UInt = 0U
  while i < branch_factor {
    let child = @model.YataHole::new(
      "cli/child-" + i.to_string() + ".md",
      contract,
      [],
      [root.hole_id],
      [],
    )
    graph = graph.add(child)
    i = i + 1U
  }

  // Detached chain rooted on a missing dependency id.
  let phantom = @model.YataHole::new("cli/phantom.md", contract, [], [], [])
  let first_detached = @model.YataHole::new(
    "cli/detached-0.md",
    contract,
    [],
    [phantom.hole_id],
    [],
  )
  graph = graph.add(first_detached)
  let mut prev = first_detached
  let mut d : UInt = 1U
  while d < detached_depth {
    let next = @model.YataHole::new(
      "cli/detached-" + d.to_string() + ".md",
      contract,
      [],
      [prev.hole_id],
      [],
    )
    graph = graph.add(next)
    prev = next
    d = d + 1U
  }

  let fanout = graph.max_branch_fanout()
  let hotspots = graph.overbranched(max_children)
  let missing = graph.holes_with_missing_dependencies()
  let detached = graph.detached_holes(max_depth)

  println("yata_nodes=\{graph.holes.length()}")
  println("max_fanout=\{fanout}")
  println("max_children_threshold=\{max_children}")
  println("overbranched=\{hotspots.length()}")
  println("missing_dependencies=\{missing.length()}")
  println("detached=\{detached.length()}")

  if hotspots.length() == 0 && missing.length() == 0 && detached.length() == 0 {
    println("topology_status=healthy")
  } else {
    println("topology_status=attention")
  }
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
