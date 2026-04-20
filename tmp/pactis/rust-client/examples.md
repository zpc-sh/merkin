# Examples

Pack and dry-run publish
```
pactis publish ./tmp/components/card --framework svelte --dry-run
```

Pack only, write bundle to file
```
pactis pack ./tmp/components/card --framework svelte --out ./card_bundle.tgz
```

Publish with token (env)
```
PACTIS_TOKEN=... pactis publish ./tmp/components/card --framework svelte
```

Validate local structure
```
pactis validate ./tmp/components/card --framework svelte
```

Minimal clap skeleton (illustrative)
```rust
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "pactis", version, about = "Pactis CLI")] 
struct Cli {
    #[arg(global = true, long)]
    base: Option<String>,
    #[arg(global = true, long)]
    token: Option<String>,
    #[arg(global = true, long, short = 'v', action = clap::ArgAction::Count)]
    verbose: u8,
    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Subcommand)]
enum Cmd {
    Pack { path: String, #[arg(long)] framework: Option<String>, #[arg(long)] out: Option<String> },
    Validate { path: String, #[arg(long)] framework: Option<String> },
    Publish { path: String, #[arg(long)] framework: String, #[arg(long)] dry_run: bool, #[arg(long)] token: Option<String> },
    Diff { old_path: String, new_path: String, #[arg(long)] framework: Option<String> },
}

fn main() {
    let _cli = Cli::parse();
    // dispatch to pactis_client library...
}
```

Workspace discovery
```
pactis workspace describe --workspace WS_ID
# GET /api/v1/workspaces/WS_ID/workspace.jsonld
```

List workspace services
```
pactis services list --workspace WS_ID
# GET /api/v1/workspaces/WS_ID/services
```

Repo service.jsonld (SDI discovery)
```
pactis repo service --owner org --repo mysvc
# GET /api/v1/repos/org/mysvc/service.jsonld
```

Secrets doctor and FILE-based keys
```
pactis keys doctor
# Reads *_API_KEY_FILE / *_API_KEY, prints status per provider

# Use SSHS-mounted secrets directory for a run
pactis publish ./component --framework svelte --secrets-dir "$SECRETSDIR"

See also: SSHS spec (../specifications/Pactis-SSHS.md) for the normative contract.
```
