# Service Manifest Guide

This page shows how to structure a Pactis service manifest and includes canonical examples from the spec.

## Purpose

<!-- @spec-include path="docs/specifications/Pactis-SRI.md" section="Purpose" -->
<!-- content is auto-generated; do not edit below this line -->
<!-- @end-spec-include -->

## Example (from SRI)

<!-- @spec-include path="docs/specifications/Pactis-SRI.md" section="Example" -->
<!-- content is auto-generated; do not edit below this line -->
<!-- @end-spec-include -->

## Tips
- Prefer CAS URLs for immutable branding assets and include integrity fields (sha256, encodingFormat).
- Keep `branding.themeColor` synchronized with `color.primary.value` in tokens.
- Validate manifests with `mix pactis.service.validate`.
