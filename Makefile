# merkin build targets
# See ../lang/mulsp/WASM_BRIDGE.md for integration context.

MULSP_PRIV  := ../lang/mulsp/priv
MUYATA_PRIV := ../lang/muyata/priv
WASM_GC_OUT := _build/wasm-gc/release/build/wasm_entry/wasm_entry.wasm
WASM_OUT    := _build/wasm/release/build/wasm_entry/wasm_entry.wasm

.PHONY: all wasm-gc wasm priv check clean

# Default: build wasm-gc (Popcorn/AtomVM target)
all: wasm-gc

# wasm-gc build — for Popcorn on AtomVM
wasm-gc:
	moon build --target wasm-gc --release --package nocsi/merkin/wasm_entry

# Standard wasm build — for wasmex NIF on standard BEAM
wasm:
	moon build --target wasm --release --package nocsi/merkin/wasm_entry

# Copy built wasm to mulsp and muyata priv directories
priv: wasm-gc
	mkdir -p $(MULSP_PRIV) $(MUYATA_PRIV)
	cp $(WASM_GC_OUT) $(MULSP_PRIV)/merkin.wasm
	cp $(WASM_GC_OUT) $(MUYATA_PRIV)/merkin.wasm
	@echo "Copied merkin.wasm to mulsp/priv and muyata/priv"
	@ls -lh $(MULSP_PRIV)/merkin.wasm

# Same but for standard wasm (wasmex path)
priv-wasm: wasm
	mkdir -p $(MULSP_PRIV) $(MUYATA_PRIV)
	cp $(WASM_OUT) $(MULSP_PRIV)/merkin.wasm
	cp $(WASM_OUT) $(MUYATA_PRIV)/merkin.wasm

# Check all packages (fast, no linking)
check:
	moon check --target wasm-gc

# Build and run tests
test:
	moon test --target wasm-gc

clean:
	moon clean
