#!/bin/bash
# Link the 1.0.11 napi cdylib against the Westmere Skia static libs.
# Requires scripts/build-westmere-musl.sh to have finished, rustc 1.99.0,
# cargo-zigbuild 0.23.4 (what was current when 1.0.11 was published) and zig 0.15.1.

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

if [ ! -f skia/out/Static/libskia.a ]; then
  echo "skia/out/Static/libskia.a is missing. Run scripts/build-westmere-musl.sh first." >&2
  exit 1
fi

REAL_ZIG="${REAL_ZIG:-/opt/cursor-toolchain/zig-x86_64-linux-0.15.1/zig}"
CARGO_ZIGBUILD="${CARGO_ZIGBUILD:-/opt/cursor-toolchain/cargo-zigbuild}"
# Stable directory. cargo-zigbuild records the absolute path of `zig` in its
# cmake toolchain cache; a mktemp path disappears and the next link fails.
WRAP="${WESTMERE_BIN:-/opt/cursor-toolchain/westmere-bin}"
mkdir -p "$WRAP"
cp "$ROOT/scripts/zig-westmere" "$WRAP/zig"
cp "$ROOT/scripts/cmake-no-avx" "$WRAP/cmake"
chmod +x "$WRAP/zig" "$WRAP/cmake"
export REAL_ZIG
export PATH="$WRAP:$HOME/.cargo/bin:/usr/local/cargo/bin:$PATH"
# Drop toolchains that point at an older wrapper path.
rm -rf "${HOME}/.cache/cargo-zigbuild"

if [ ! -x "$CARGO_ZIGBUILD" ]; then
  echo "cargo-zigbuild missing at $CARGO_ZIGBUILD" >&2
  exit 1
fi
ln -sfn "$CARGO_ZIGBUILD" "$WRAP/cargo-zigbuild"

# .cargo/config.toml sets target-cpu=westmere for this triple.
rustup run 1.99.0 rustc --version
rustup target list --toolchain 1.99.0 --installed | grep -qx x86_64-unknown-linux-musl

if ! command -v yarn >/dev/null 2>&1; then
  corepack enable
  corepack prepare yarn@4.18.1 --activate
fi

if [ ! -d node_modules/@napi-rs/cli ]; then
  yarn install --immutable
fi

# napi's -x flag shells out to cargo-zigbuild. RUSTUP_TOOLCHAIN pins 1.99.0,
# the channel in rust-toolchain.toml at v1.0.11.
export RUSTUP_TOOLCHAIN=1.99.0
set +e
yarn build --target x86_64-unknown-linux-musl -x -- --locked
yarn_rc=$?
set -e
# napi-cli 3.x then tries to mkdtemp '/.workspace.napi-stage-*' and dies with
# EACCES. The cdylib is already linked; publish that file under the npm name.
SO=target/x86_64-unknown-linux-musl/release/libcanvas.so
if [[ ! -f skia.linux-x64-musl.node ]]; then
  if [[ ! -f "$SO" ]]; then
    echo "no cdylib and yarn exited $yarn_rc" >&2
    exit "$yarn_rc"
  fi
  cp -f "$SO" skia.linux-x64-musl.node
  echo "napi stage dir was not created (exit $yarn_rc); copied $SO"
fi

ls -l skia.linux-x64-musl.node
file skia.linux-x64-musl.node
sha256sum skia.linux-x64-musl.node
