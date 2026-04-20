# Svelte Component: Prepare & Publish

This guide shows how to scaffold a Svelte component and publish it to the Pactis marketplace.

## 1) Using Pactis CLI (recommended)

Build the CLI escript:

```
cd priv/tools/pactis_cli
mix escript.build
```

Create a component scaffold (Svelte):

```
./pactis_cli component new Card --framework svelte --path tmp/components/card --typescript
```

Dry‑run publish (validate & package without uploading):

```
./pactis_cli component publish tmp/components/card --framework svelte --dry-run
```

Publish (requires token):

```
PACTIS_TOKEN=your_token_here \
  ./pactis_cli component publish tmp/components/card --framework svelte
```

## 2) Using Mix tasks directly

```
# Scaffold
mix pactis.new Card --framework svelte --path tmp/components/card --typescript

# Validate
mix pactis.publish tmp/components/card --framework svelte --dry-run

# Publish
PACTIS_TOKEN=your_token_here mix pactis.publish tmp/components/card --framework svelte
```

## 3) Local example in repo

A minimal example exists at `tmp/components/card`:
- `Card.svelte`
- `package.json`
- `README.md`

You can run the dry‑run publish against this folder with the commands above.

## Notes
- `--dry-run` prints validation, files discovered, and bundle size without contacting the server.
- Use `--version`, `--description`, `--tags`, `--category`, `--license`, and `--private` to customize metadata.
- Svelte assets for the Phoenix app are independent (`assets/svelte/*`) and built via `npm run build:svelte`; they are not required for publishing a standalone UI component.
