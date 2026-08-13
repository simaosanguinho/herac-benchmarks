#!/usr/bin/env bash
set -euo pipefail

# ---------------------------
# Config
# ---------------------------
RS_FILE="src/lib.rs"
BASE="dynamic_html_guest"
OUTPUT_DIR="../x64/debug"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR=$(realpath "$OUTPUT_DIR")

RUST_TARGET="wasm32-wasip1"

# ---------------------------
# Check/install Rust Target
# ---------------------------
if ! rustup target list | grep -q "${RUST_TARGET} (installed)"; then
    echo "Rust target not found. Installing ${RUST_TARGET}..."
    rustup target add "${RUST_TARGET}"
    echo "Rust target installed"
else
    echo "Rust target found: ${RUST_TARGET}"
fi

# ---------------------------
# Compile Rust -> WASM
# ---------------------------
WASM_FILE="$OUTPUT_DIR/${BASE}-wasip1.wasm"
echo "Compiling $RS_FILE → $WASM_FILE"

# Map your C linker flags directly to Rust's Wasm linker
export RUSTFLAGS="\
    -C link-arg=--export=__data_end \
    -C link-arg=--export=__heap_base \
    -C link-arg=--export=malloc \
    -C link-arg=--export=free \
    -C link-arg=--export=__wasm_call_ctors \
    -C link-arg=--no-entry \
    -C link-arg=--allow-undefined \
    -C link-arg=--gc-sections \
    -C link-arg=--strip-all \
    -C link-arg=--export=run"

# Invoke Cargo to handle the dependencies
cargo build --locked --target="${RUST_TARGET}" --release

# Extract the generated Wasm file from Cargo's output
CARGO_WASM=$(find target/"${RUST_TARGET}"/release -maxdepth 1 -name "*.wasm" | head -n 1)
cp "$CARGO_WASM" "$WASM_FILE"

# ---------------------------
# Compile WASM -> AOT
# ---------------------------
AOT_FILE="$OUTPUT_DIR/${BASE}.aot"
echo "Compiling $WASM_FILE → $AOT_FILE"
../../../../hyperlight-wasm/target/debug/hyperlight-wasm-aot compile "$WASM_FILE" "$AOT_FILE"

echo "Done! Generated files:"
ls -lh "$WASM_FILE" "$AOT_FILE"
