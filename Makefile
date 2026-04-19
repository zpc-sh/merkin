# merkin build targets
# See ../lang/mulsp/WASM_BRIDGE.md for integration context.

MULSP_PRIV  := ../lang/mulsp/priv
MUYATA_PRIV := ../lang/muyata/priv

# wasm_entry: AtomVM/Popcorn (_start + all exports)
WASM_GC_ENTRY := _build/wasm-gc/release/build/wasm_entry/wasm_entry.wasm
WASM_ENTRY    := _build/wasm/release/build/wasm_entry/wasm_entry.wasm

# wasm_lib: pure library, no _start (WasmEdge, wasmex)
WASM_GC_LIB   := _build/wasm-gc/release/build/wasm_lib/wasm_lib.wasm
WASM_LIB      := _build/wasm/release/build/wasm_lib/wasm_lib.wasm

# native CLI
NATIVE_EXE    := _build/native/release/build/cmd/main/main.exe
NATIVE_C      := _build/native/release/build/cmd/main/main.c

VERSION       ?= v0.1.0
ZIG_TARGET    ?= native

.PHONY: all wasm-gc wasm wasm-all cli simd release dist priv priv-lib check test test-simd test-yata prove-offloaded mu-lang-handoff wasm-plan-drift triad-contract-sync clean

# Default: build wasm-gc AtomVM target
all: wasm-gc

# wasm_entry (AtomVM/Popcorn): _start + all api exports
wasm-gc:
	moon build --target wasm-gc --release --package zpc/merkin/wasm_entry
	moon build --target wasm-gc --release --package zpc/merkin/wasm_lib

# Standard wasm (WasmEdge/wasmex)
wasm:
	moon build --target wasm --release --package zpc/merkin/wasm_entry
	moon build --target wasm --release --package zpc/merkin/wasm_lib

# All wasm targets
wasm-all: wasm-gc wasm

# Standalone native CLI binary
cli:
	moon build --target native --release --package zpc/merkin/cmd/main
	cp $(NATIVE_EXE) merkin
	@echo "CLI binary: ./merkin  ($(shell du -sh merkin | cut -f1))"

# Build + test the SIMD package (native only — AVX-VNNI + AVX-NE-CONVERT stubs)
simd:
	moon test --target native --package zpc/merkin/simd

# Full release: test → build all → dist → seal
release:
	VERSION=$(VERSION) ZIG_TARGET=$(ZIG_TARGET) tools/release.sh

# Quick dist without tests
dist:
	VERSION=$(VERSION) ZIG_TARGET=$(ZIG_TARGET) tools/release.sh --skip-tests

# Copy wasm_entry (AtomVM) to mulsp/muyata priv
priv: wasm-gc
	mkdir -p $(MULSP_PRIV) $(MUYATA_PRIV)
	cp $(WASM_GC_ENTRY) $(MULSP_PRIV)/merkin.wasm
	cp $(WASM_GC_ENTRY) $(MUYATA_PRIV)/merkin.wasm
	@echo "Copied merkin.wasm → mulsp/priv and muyata/priv"
	@ls -lh $(MULSP_PRIV)/merkin.wasm

# Copy wasm_lib (WasmEdge/wasmex) to priv directories
priv-lib: wasm-gc
	mkdir -p $(MULSP_PRIV) $(MUYATA_PRIV)
	cp $(WASM_GC_LIB) $(MULSP_PRIV)/merkin-lib.wasm
	cp $(WASM_GC_LIB) $(MUYATA_PRIV)/merkin-lib.wasm

# Standard wasm to priv (wasmex path)
priv-wasm: wasm
	mkdir -p $(MULSP_PRIV) $(MUYATA_PRIV)
	cp $(WASM_ENTRY) $(MULSP_PRIV)/merkin.wasm
	cp $(WASM_ENTRY) $(MUYATA_PRIV)/merkin.wasm

# Check all packages (fast, no linking)
check:
	moon check --target wasm-gc

# Build and run tests (wasm-gc + native SIMD)
test:
	moon test --target wasm-gc
	moon test --target native --package zpc/merkin/simd

# wasm-gc only (fast, skips SIMD native build)
test-wasm:
	moon test --target wasm-gc

# SIMD native tests only
test-simd:
	moon test --target native --package zpc/merkin/simd

# Focused Yata verification suite
test-yata:
	moon test model/yata_test.mbt --target wasm-gc
	moon test model/yata_protocol_test.mbt --target wasm-gc
	moon test model/yata_addressing_test.mbt --target wasm-gc

# SAT/SMT offloaded proof runner (Moon + external solver)
prove-offloaded:
	tools/moon-prove-offloaded.sh storage

# Curated compiler/runtime docs bundle for Mu language handoff
mu-lang-handoff:
	tools/mu-lang-compiler-docs-bundle.sh

# Emit finger.plan.wasm + drift summary using sibling repo refs
wasm-plan-drift:
	tools/yata-wasm-plan-drift-sync.sh

# Emit triad contract JSON + ABI/branch drift summary across merkin/mu/lang
triad-contract-sync:
	tools/yata-triad-contract-sync.sh

clean:
	moon clean
