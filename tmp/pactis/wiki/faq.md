# FAQ

**Why JSON-LD?**: Interop + semantics. Specs can be consumed broadly and transformed reliably.

**Can we embed tests?**: Yes. Use the SpecTest vocabulary; results are persisted as JSON-LD.

**How do we distribute?**: Use `mix pactis.jsonld.package` to produce a tar; CI uploads it.

**Is schema validation supported?**: Planned via `ExJsonSchema` for `schemaRef`.

See: [Glossary](glossary.md)
