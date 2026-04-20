# Pactis-GRI: Generator Registry Interface

- Status: Draft
- Last Updated: 2025-09-26
- Owners: Pactis Core
- Related: Pactis-API.md, Pactis-PRI.md
- Notice: Pactis™ is an open specification by Pactis and is not affiliated with any other entity using similar names. ™ indicates an unregistered trademark claim.

## Purpose
Advertise and resolve generator capabilities, inputs, and versions used to produce deterministic artifacts.

## Scope
- Query capabilities; fetch GeneratorDescriptor; resolve semver ranges to exact versions.

## API Sketch
- GET /generators: list with capabilities and versions.
- GET /generators/{id}: GeneratorDescriptor.

## Security Considerations
- Auth required to publish/update descriptors; public read may be allowed.
- Validate semver and provenance links; prevent spoofing of capabilities.

## Conformance
- Stable identifiers; semver discipline; provenance linkage to artifacts.
