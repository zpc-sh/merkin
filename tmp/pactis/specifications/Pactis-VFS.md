# Pactis-VFS: Artifact File Serving Profile

- Status: Draft
- Last Updated: 2025-09-26
- Owners: Pactis Core
- Related: Pactis-API.md
- Notice: Pactis™ is an open specification by Pactis and is not affiliated with any other entity using similar names. ™ indicates an unregistered trademark claim.

## Purpose
Profile for serving content‑addressed artifacts and related files with VFS semantics.

## Scope
- CAS addressing; range requests; integrity checks; content types.

## API Sketch
- GET /cas/{digest}: resolve and stream by digest.
- HEAD /cas/{digest}: metadata, size, integrity headers.

## Conformance
- Strong integrity headers; byte‑for‑byte stability; caching semantics.

## Security Considerations
- Require authorization for private artifacts; support time-bound signed URLs.
- Return integrity headers (ETag, Digest) and enforce range request limits.
