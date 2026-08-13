#!/usr/bin/env bash
set -euo pipefail

RS_FILE="src/lib.rs"
BASE="mst_guest"
OUTPUT_DIR="../x64/debug"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR=$(realpath "$OUTPUT_DIR")
RUST_TARGET="wasm32-wasip1"

if ! rustup target list | grep -q "${RUST_TARGET} (installed)"; then
    rustup target add "${RUST_TARGET}"
fi

WASM_FILE="$OUTPUT_DIR/${BASE}-wasip1.wasm"
echo "Compiling Rust → WASM: $WASM_FILE"

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

cargo build --locked --target="${RUST_TARGET}" --release

CARGO_WASM=$(find target/"${RUST_TARGET}"/release -maxdepth 1 -name "*.wasm" | head -n 1)
cp "$CARGO_WASM" "$WASM_FILE"

AOT_FILE="$OUTPUT_DIR/${BASE}.aot"
echo "Compiling WASM → AOT: $AOT_FILE"

../../../../hyperlight-wasm/target/debug/hyperlight-wasm-aot compile "$WASM_FILE" "$AOT_FILE"

echo "Done! Generated:"
ls -lh "$WASM_FILE" "$AOT_FILE"
