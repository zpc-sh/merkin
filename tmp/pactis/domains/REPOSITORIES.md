# Pactis.Repositories Domain

- Purpose: Owns repository resources and Git artifacts used for conversation-integrated development and storage.
- Domain module: `Pactis.Repositories`
- Resource modules (registered in this domain):
  - `Pactis.Repositories.Repository`
  - `Pactis.Repositories.RepositoryCommit`
  - `Pactis.Repositories.RepositoryTree`
  - `Pactis.Repositories.RepositoryBlob`
  - `Pactis.Repositories.RepositoryRef`

Usage
- Use `domain: Pactis.Repositories` when performing Ash operations on commit/tree/blob/ref.
- Repositories can be accessed via `Pactis.Core` convenience functions temporarily, but the canonical domain is `Pactis.Repositories`.
- Example:
  - `Ash.read(Pactis.Repositories.Repository, domain: Pactis.Core)` (existing API surface)
  - `Ash.read(Pactis.Repositories.RepositoryCommit, domain: Pactis.Repositories)` (canonical)

Notes
- Repository registration also exists under `Pactis.Core` to preserve current APIs; plan to route callers to `Pactis.Repositories` directly over time.
- Spec resources live under `Pactis.Spec` and relate to repositories via `workspace_id` and `repository_id`.
