# Terminal UI (TUI) via Raxol

Pactis can generate Terminal UIs from blueprints using the Raxol-based generator.

- Framework key: `:tui`
- Module: `Pactis.Generators.TuiGenerator`
- Under the hood: `Pactis.Formats.TerminalUiGenerator`

## Generate

```elixir
{:ok, %{files: files, metadata: meta}} =
  Pactis.Generators.Registry.generate_for_framework(blueprint, :tui)
```

Inspect `files` to write to disk or preview. Metadata includes format info and features.

## Demo

- Launch instructions are embedded in generated files (Raxol app module). Typically:
  - iex -S mix
  - MyApp.TerminalUi.<Resource>App.start()

For a quick overview, see `lib/pactis/formats/terminal_ui_generator.ex` and search for `TerminalUi` in the codebase.
