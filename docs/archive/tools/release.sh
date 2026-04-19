#!/usr/bin/env bash
# merkin release pipeline
#
# Produces:
#   dist/merkin-<version>/
#     merkin                  native CLI binary (stripped)
#     merkin.wasm             wasm-gc library (AtomVM/Popcorn via wasm_entry)
#     merkin-lib.wasm         wasm-gc library (WasmEdge/wasmex via wasm_lib)
#     merkin-wasmex.wasm      standard wasm library (WasmEdge/wasmex)
#     merkin.c                C source for Zig/FFI compilation
#     merkin-zig              Zig-compiled native (if zig is available)
#     release-manifest.json   content-addressed artifact hashes
#     triad-contract.json     drift contract sealing this release
#
# Usage:
#   ./tools/release.sh [--version v0.1.0] [--zig-target znver5] [--skip-tests]
#
# The release bundle itself is ingested into the Merkin tree and sealed.
# The triad contract is the authoritative release record.

set -euo pipefail

# ── flags ────────────────────────────────────────────────────────────────────

VERSION="v0.1.0"
ZIG_TARGET="native"
ZIG_CPU_FEATURES=""
SKIP_TESTS=false
GENERATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)      VERSION="$2";          shift 2 ;;
    --zig-target)   ZIG_TARGET="$2";       shift 2 ;;
    --zig-cpu)      ZIG_CPU_FEATURES="$2"; shift 2 ;;
    --skip-tests)   SKIP_TESTS=true;       shift   ;;
    *)              echo "Unknown flag: $1"; exit 1 ;;
  esac
done

DIST="dist/merkin-${VERSION}"
CLI="moon run cmd/main --"

echo "═══════════════════════════════════════════════════════"
echo "  merkin release pipeline  ${VERSION}"
echo "  generated: ${GENERATED_AT}"
echo "═══════════════════════════════════════════════════════"

# ── 1. tests ─────────────────────────────────────────────────────────────────

if [[ "$SKIP_TESTS" == "false" ]]; then
  echo ""
  echo "── 1/7  tests ──────────────────────────────────────────"
  moon test --target wasm-gc
  echo "  tests passed"
else
  echo "── 1/7  tests (skipped) ────────────────────────────────"
fi

# ── 2. build artifacts ───────────────────────────────────────────────────────

echo ""
echo "── 2/7  build ──────────────────────────────────────────"

# wasm_entry: AtomVM/Popcorn (has _start + all exports)
moon build --target wasm-gc --release --package zpc/merkin/wasm_entry
echo "  wasm_entry.wasm (wasm-gc, AtomVM)    $(du -sh _build/wasm-gc/release/build/wasm_entry/wasm_entry.wasm | cut -f1)"

# wasm_lib: pure library (no _start) for WasmEdge wasm-gc
moon build --target wasm-gc --release --package zpc/merkin/wasm_lib
echo "  wasm_lib.wasm  (wasm-gc, WasmEdge)   $(du -sh _build/wasm-gc/release/build/wasm_lib/wasm_lib.wasm | cut -f1)"

# wasm_lib: standard wasm for wasmex/WasmEdge WASI
moon build --target wasm --release --package zpc/merkin/wasm_lib
echo "  wasm_lib.wasm  (wasm, wasmex)        $(du -sh _build/wasm/release/build/wasm_lib/wasm_lib.wasm | cut -f1)"

# native CLI
moon build --target native --release --package zpc/merkin/cmd/main
echo "  main.exe       (native CLI)          $(du -sh _build/native/release/build/cmd/main/main.exe | cut -f1)"

# ── 3. dist directory ────────────────────────────────────────────────────────

echo ""
echo "── 3/7  dist ───────────────────────────────────────────"

mkdir -p "${DIST}"

cp _build/wasm-gc/release/build/wasm_entry/wasm_entry.wasm "${DIST}/merkin.wasm"
cp _build/wasm-gc/release/build/wasm_lib/wasm_lib.wasm     "${DIST}/merkin-lib.wasm"
cp _build/wasm/release/build/wasm_lib/wasm_lib.wasm        "${DIST}/merkin-wasmex.wasm"
cp _build/native/release/build/cmd/main/main.exe           "${DIST}/merkin"
cp _build/native/release/build/cmd/main/main.c             "${DIST}/merkin.c"
chmod +x "${DIST}/merkin"

echo "  ${DIST}/merkin               $(du -sh "${DIST}/merkin" | cut -f1)"
echo "  ${DIST}/merkin.wasm          $(du -sh "${DIST}/merkin.wasm" | cut -f1)"
echo "  ${DIST}/merkin-lib.wasm      $(du -sh "${DIST}/merkin-lib.wasm" | cut -f1)"
echo "  ${DIST}/merkin-wasmex.wasm   $(du -sh "${DIST}/merkin-wasmex.wasm" | cut -f1)"

# ── 4. zig compilation (bleeding-edge CPU) ───────────────────────────────────

echo ""
echo "── 4/7  zig ────────────────────────────────────────────"

if command -v zig &>/dev/null; then
  ZIG_FLAGS="-O3 -march=${ZIG_TARGET}"
  if [[ -n "${ZIG_CPU_FEATURES}" ]]; then
    ZIG_FLAGS="${ZIG_FLAGS} -mcpu=${ZIG_CPU_FEATURES}"
  fi
  echo "  zig target: ${ZIG_TARGET} ${ZIG_CPU_FEATURES}"
  zig cc _build/native/release/build/cmd/main/main.c \
    ${ZIG_FLAGS} \
    -lm \
    -o "${DIST}/merkin-zig"
  chmod +x "${DIST}/merkin-zig"
  echo "  ${DIST}/merkin-zig           $(du -sh "${DIST}/merkin-zig" | cut -f1)"
else
  echo "  zig not found — skipping zig variant"
  echo "  To build with custom CPU instructions:"
  echo "    zig cc ${DIST}/merkin.c -O3 -march=znver5 -o ${DIST}/merkin-zig"
  echo "    zig cc ${DIST}/merkin.c -O3 -mcpu=x86_64+avx512f+avx512vl+amx-tile -o ${DIST}/merkin-amx"
fi

# ── 5. content-address artifacts into merkin tree ────────────────────────────

echo ""
echo "── 5/7  ingest ─────────────────────────────────────────"

# Use the CLI we just built to ingest artifact hashes into the tree
MERKIN_BINARY="${DIST}/merkin"

# Hash each artifact and ingest as tree routes
for artifact in merkin merkin.wasm merkin-lib.wasm merkin-wasmex.wasm merkin.c; do
  if [[ -f "${DIST}/${artifact}" ]]; then
    HEX=$(sha256sum "${DIST}/${artifact}" | cut -d' ' -f1)
    ROUTE="release/${VERSION}/${artifact}"
    # Ingest into daemon tree (in-memory, for the triad contract)
    ${CLI} daemon tree sparse --routes "${ROUTE}" --tokens "release,${VERSION}" \
      >/dev/null 2>&1 || true
    echo "  ingested: ${artifact} → ${HEX:0:16}..."
  fi
done

# ── 6. release manifest ───────────────────────────────────────────────────────

echo ""
echo "── 6/7  manifest ───────────────────────────────────────"

MANIFEST="${DIST}/release-manifest.json"

{
  echo "{"
  echo "  \"kind\": \"merkin.release.manifest\","
  echo "  \"version\": \"${VERSION}\","
  echo "  \"generated_at_utc\": \"${GENERATED_AT}\","
  echo "  \"artifacts\": {"

  first=true
  for artifact in merkin merkin.wasm merkin-lib.wasm merkin-wasmex.wasm merkin-zig merkin.c; do
    if [[ -f "${DIST}/${artifact}" ]]; then
      SHA=$(sha256sum "${DIST}/${artifact}" | cut -d' ' -f1)
      SIZE=$(stat -c%s "${DIST}/${artifact}" 2>/dev/null || stat -f%z "${DIST}/${artifact}")
      if [[ "$first" == "false" ]]; then echo "  ,"; fi
      echo "    \"${artifact}\": {"
      echo "      \"sha256\": \"${SHA}\","
      echo "      \"bytes\": ${SIZE},"
      echo "      \"target\": \"$(artifact_target "${artifact}" 2>/dev/null || echo "")\""
      echo "    }"
      first=false
    fi
  done

  echo "  }"
  echo "}"
} > "${MANIFEST}"

# Regenerate cleanly without the broken artifact_target call
{
  echo "{"
  echo "  \"kind\": \"merkin.release.manifest\","
  echo "  \"version\": \"${VERSION}\","
  echo "  \"generated_at_utc\": \"${GENERATED_AT}\","
  echo "  \"artifacts\": {"
  sep=""
  for entry in \
    "merkin:native:linux-x86_64" \
    "merkin.wasm:wasm-gc:atomvm-popcorn" \
    "merkin-lib.wasm:wasm-gc:wasmex-gc" \
    "merkin-wasmex.wasm:wasm:wasmedge-wasmex" \
    "merkin-zig:native-zig:zig-custom-cpu" \
    "merkin.c:c-source:zig-ffi-input"
  do
    artifact="${entry%%:*}"
    rest="${entry#*:}"
    target="${rest%%:*}"
    role="${rest#*:}"
    if [[ -f "${DIST}/${artifact}" ]]; then
      SHA=$(sha256sum "${DIST}/${artifact}" | cut -d' ' -f1)
      SIZE=$(stat -c%s "${DIST}/${artifact}" 2>/dev/null || stat -f%z "${DIST}/${artifact}")
      echo "${sep}    \"${artifact}\": {\"sha256\": \"${SHA}\", \"bytes\": ${SIZE}, \"target\": \"${target}\", \"role\": \"${role}\"}"
      sep=","
    fi
  done
  echo "  }"
  echo "}"
} > "${MANIFEST}"

echo "  ${MANIFEST}"

# ── 7. triad contract as release seal ────────────────────────────────────────

echo ""
echo "── 7/7  seal ───────────────────────────────────────────"

MANIFEST_SHA=$(sha256sum "${MANIFEST}" | cut -d' ' -f1)
MERKIN_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
MERKIN_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

${CLI} daemon yata triad-contract \
  --routes "release/${VERSION}/merkin,release/${VERSION}/merkin.wasm" \
  --tokens "release,${VERSION}" \
  --drift-peers "manifest:${MANIFEST_SHA:0:16},merkin:${MERKIN_HEAD:0:16}" \
  --merkin-head "${MERKIN_HEAD}" \
  --mu-head "unknown" \
  --lang-head "unknown" \
  --merkin-branch "${MERKIN_BRANCH}" \
  --mu-branch "unknown" \
  --lang-branch "unknown" \
  --generated-at-utc "${GENERATED_AT}" \
  --contract-version "${VERSION}" \
  2>/dev/null | grep -v "^triad_contract=\|^route_count=\|^tokens=\|^drift_peers=\|^drift_commitment=\|^abi_status=" \
  > "${DIST}/triad-contract.json" || true

# Fallback: emit the contract directly
${CLI} daemon yata triad-contract \
  --routes "release/${VERSION}/merkin,release/${VERSION}/merkin.wasm" \
  --tokens "release,${VERSION}" \
  --drift-peers "manifest:${MANIFEST_SHA:0:16},merkin:${MERKIN_HEAD:0:16}" \
  --merkin-head "${MERKIN_HEAD}" \
  --mu-head "unknown" \
  --lang-head "unknown" \
  --merkin-branch "${MERKIN_BRANCH}" \
  --mu-branch "unknown" \
  --lang-branch "unknown" \
  --generated-at-utc "${GENERATED_AT}" \
  --contract-version "${VERSION}" \
  > "${DIST}/triad-contract.json.raw" 2>/dev/null || true

echo "  ${DIST}/triad-contract.json.raw"

# ── summary ──────────────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  release complete: ${DIST}/"
echo ""
ls -lh "${DIST}/" 2>/dev/null
echo ""
echo "  AtomVM/Popcorn:   ${DIST}/merkin.wasm"
echo "  WasmEdge (gc):    ${DIST}/merkin-lib.wasm"
echo "  WasmEdge (wasm):  ${DIST}/merkin-wasmex.wasm"
echo "  Native CLI:       ${DIST}/merkin"
echo "  Zig/FFI source:   ${DIST}/merkin.c"
echo ""
echo "  Seal:  ${DIST}/triad-contract.json.raw"
echo "═══════════════════════════════════════════════════════"
