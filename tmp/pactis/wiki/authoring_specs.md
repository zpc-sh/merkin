# Authoring Specs

## Options
- Native JSON-LD authoring using the Spec context
- Markdown → JSON-LD conversion for table-oriented content

## Commands
- Convert Markdown: `mix pactis.jsonld.md_to_jsonld --in docs/specs.md --out priv/jsonld/tmp --type SpecResource`
- Validate JSON-LD: `mix pactis.jsonld.validate --dir priv/jsonld --strict`

## Templates
- Use templates in `priv/jsonld/resources/Templates/` as a starting point.

See: [Testing & Results](testing_results.md)
