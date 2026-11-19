#!/bin/bash
# Rebuild @napi-rs/canvas 1.0.11's linux-x64-musl binding for Westmere (no AVX).
# Source tree must be the v1.0.11 commit (adce718ec8ff82f9e896875752fd621c46b1c04e).
# Does not publish, does not touch Brooooooklyn/canvas.

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

REAL_ZIG="${REAL_ZIG:-/opt/cursor-toolchain/zig-x86_64-linux-0.15.1/zig}"
if [ ! -x "$REAL_ZIG" ]; then
  echo "Missing zig 0.15.1 at $REAL_ZIG" >&2
  exit 1
fi

WRAP=$(mktemp -d)
cp "$ROOT/scripts/zig-westmere" "$WRAP/zig"
chmod +x "$WRAP/zig"
export REAL_ZIG
export PATH="$WRAP:$PATH"

# Refuse to compile if the wrapper is not actually first.
hash -r
command -v zig
zig version

echo | zig cc -target x86_64-linux-musl -dM -E -x c - > "$WRAP/macros.txt"
if ! grep -q '#define __SSE4_2__ 1' "$WRAP/macros.txt"; then
  echo "westmere wrapper did not enable SSE4.2" >&2
  exit 1
fi
if grep -q '#define __AVX__ 1' "$WRAP/macros.txt"; then
  echo "westmere wrapper enabled AVX; refusing to build" >&2
  exit 1
fi

export SKIP_SYNC_SK_DEPS="${SKIP_SYNC_SK_DEPS:-0}"

# ninja -j is capped because a 4-core VM OOMs on a full Skia C++ link fan-out.
if [ ! -x /usr/bin/ninja ]; then
  echo "ninja is not installed" >&2
  exit 1
fi
NINJA_WRAP=$(mktemp -d)
cat > "$NINJA_WRAP/ninja" << 'EOF'
#!/bin/sh
exec /usr/bin/ninja -j3 "$@"
EOF
chmod +x "$NINJA_WRAP/ninja"
export PATH="$NINJA_WRAP:$WRAP:$PATH"

node ./scripts/build-skia.js --target=x86_64-unknown-linux-musl

echo "Skia static libs are in skia/out/Static"
