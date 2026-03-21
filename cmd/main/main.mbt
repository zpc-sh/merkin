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
  println("Flags:")
  println("  --action capabilities|put|sparse|diff|demo")
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
  let total = s.length() * 4
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
  if pos == total {
    Bytes::from_array(buf)
  } else {
    let exact_buf = FixedArray::make(pos, b'\x00')
    for i = 0; i < pos; i = i + 1 {
      exact_buf[i] = buf[i]
    }
    Bytes::from_array(exact_buf)
  }
}
