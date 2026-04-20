# Contributing Docs (Spec-Anchored)

To avoid drift, compose docs from spec files using include markers. Use the `mix pactis.docs.sync` task to inject canonical sections from spec files.

## Include Markers
In any Markdown file under `docs/`, add markers like:

```
<!-- @spec-include path="docs/specifications/Pactis-DAI.md" section="Endpoints" -->
<!-- content is auto-generated; do not edit below this line -->
... will be replaced ...
<!-- @end-spec-include -->
```

- `path` is relative to repo root.
- `section` must match a Markdown heading in the source file.

## Sync
Run:
```
mix pactis.docs.sync
```
This replaces include blocks with content from the specified spec files.

## CI Suggestion
Add a CI step to run `mix pactis.docs.sync` and fail if there are uncommitted changes (prevents drift).
