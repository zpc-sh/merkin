# Pactis AI Docs Site (MkDocs)

This directory contains a minimal MkDocs configuration for publishing Pactis AI discovery, ethics, and specifications.

## Quickstart

- Install MkDocs + Material theme:
  - `pip install mkdocs mkdocs-material`
- From the repo root, run:
  - `mkdocs serve --config-file docs/site/mkdocs.yml`
- Open the local server URL to browse the docs.

## Structure

- `docs/AI_DISCOVERY.md` — Canonical AI discovery and ethics endpoints
- `docs/specifications/Pactis-LGI.md` — LGI spec (Language Gateway Interface)
- `docs/specifications/Pactis-RSI.md` — RSI spec (Repository Service Interface)
- `docs/specifications/Pactis-SDI.md` — SDI spec (Service Self-Description)
- `docs/howto/secrets_ephemeral_cli.md` — SSHS secrets mounting
- `docs/wiki/specapi_for_ai.md` — SpecAPI guide for agents/LLMs

Update `docs/site/mkdocs.yml` to adjust navigation.
