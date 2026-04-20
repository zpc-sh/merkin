# Badges

We use Shields.io badges in the repo README to quickly signal key capabilities:

- SSHS: readiness of the Secure Secrets via SSH keys model
- JSON‑LD: availability of JSON‑LD validation/verification/import tooling
- Docs: presence of a Material‑based MkDocs site config

Update badges
- Preferred: `mix pactis.badges.generate` inserts/updates the badges block in README between markers:

  ```
  <!-- badges:start -->
  ... auto-generated badges ...
  <!-- badges:end -->
  ```

- Manual: edit README.md and adjust the badge lines as needed.

Notes
- CI status badges can be added once the repository owner/name is finalized, e.g.
  `https://github.com/<owner>/<repo>/actions/workflows/ci.yml/badge.svg`.
- On forks, badges still render since Shields are hosted; links point to files in this repo.

