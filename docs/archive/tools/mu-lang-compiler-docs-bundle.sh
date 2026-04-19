#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Build a curated compiler/runtime documentation bundle for Mu language handoff.

Usage:
  tools/mu-lang-compiler-docs-bundle.sh [options]

Options:
  --out-dir <dir>       Output directory
                        (default: _build/handoff/mu-lang-compiler-docs/latest)
  --manifest <path>     Manifest file listing relative doc paths
                        (default: docs/MU_LANG_COMPILER_HANDOFF_MANIFEST.txt)
  --archive-name <name> Archive name
                        (default: merkin-mu-lang-compiler-docs.tar.gz)
  -h, --help            Show this help

Notes:
  - Manifest lines beginning with '#' are ignored.
  - Empty lines are ignored.
EOF
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/_build/handoff/mu-lang-compiler-docs/latest"
MANIFEST="$ROOT_DIR/docs/MU_LANG_COMPILER_HANDOFF_MANIFEST.txt"
ARCHIVE_NAME="merkin-mu-lang-compiler-docs.tar.gz"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --manifest)
      MANIFEST="$2"
      shift 2
      ;;
    --archive-name)
      ARCHIVE_NAME="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$MANIFEST" ]]; then
  printf 'Manifest not found: %s\n' "$MANIFEST" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
rm -rf "$OUT_DIR/docs"
mkdir -p "$OUT_DIR/docs"

summary_file="$OUT_DIR/summary.txt"
archive_file="$OUT_DIR/$ARCHIVE_NAME"
manifest_copy="$OUT_DIR/manifest.txt"

cp "$MANIFEST" "$manifest_copy"

copied_count=0
while IFS= read -r line; do
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  if [[ -z "$line" || "${line:0:1}" == "#" ]]; then
    continue
  fi

  src="$ROOT_DIR/$line"
  if [[ ! -f "$src" ]]; then
    printf 'Manifest entry is not a file: %s\n' "$line" >&2
    exit 1
  fi

  dst="$OUT_DIR/$line"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  copied_count=$((copied_count + 1))
done <"$MANIFEST"

generated_at_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
{
  printf 'mu_lang_compiler_handoff_bundle\n'
  printf 'generated_at_utc=%s\n' "$generated_at_utc"
  printf 'manifest=%s\n' "$MANIFEST"
  printf 'copied_files=%d\n' "$copied_count"
  printf 'archive=%s\n' "$archive_file"
} >"$summary_file"

tar -czf "$archive_file" -C "$OUT_DIR" docs summary.txt manifest.txt

printf 'bundle_ready=%s\n' "$archive_file"
printf 'summary=%s\n' "$summary_file"
printf 'files=%d\n' "$copied_count"
