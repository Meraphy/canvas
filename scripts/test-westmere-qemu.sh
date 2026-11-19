#!/bin/bash
# Isolated Westmere test. Does not use the n8n image, a database, or credentials.
#
# Needs:
#   qemu-x86_64-static
#   Alpine 3.24 rootfs at /tmp/alpine (ldd is the musl wrapper, so
#   js-binding.js isMusl() is true inside the chroot)
#   official Node 26.13.0 musl at /tmp/node-musl-26.13.0/bin/node
#   libatomic installed in the rootfs (the nodejs.org binary needs it)
#   pdfjs-dist@6.3.289 installed somewhere and copied into the chroot
#   DejaVu fonts in the rootfs (apk package font-dejavu)
#
# The rebuilt binding must already be at ./skia.linux-x64-musl.node.

set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
ALPINE=${ALPINE:-/tmp/alpine}
NODE26=${NODE26:-/tmp/node-musl-26.13.0/bin/node}
PDFJS=${PDFJS:-/tmp/canvas-inv/pdfjs/node_modules/pdfjs-dist}
PDF=${PDF:-/tmp/canvas-inv/westmere.pdf}
CPU=${CPU:-Westmere-v1}

sudo mkdir -p "$ALPINE/opt/wtest/node_modules/@napi-rs/canvas" "$ALPINE/usr/local/bin"
sudo cp "$NODE26" "$ALPINE/usr/local/bin/node26"
sudo cp /usr/bin/qemu-x86_64-static "$ALPINE/usr/bin/qemu-x86_64-static"
for f in index.js index.d.ts geometry.js js-binding.js load-image.js node-canvas.js node-canvas.d.ts package.json; do
  sudo cp "$ROOT/$f" "$ALPINE/opt/wtest/node_modules/@napi-rs/canvas/$f"
done
sudo cp "$ROOT/skia.linux-x64-musl.node" "$ALPINE/opt/wtest/node_modules/@napi-rs/canvas/skia.linux-x64-musl.node"
sudo cp "$ROOT/scripts/test-westmere.mjs" "$ALPINE/opt/wtest/test.mjs"
sudo cp "$PDF" "$ALPINE/opt/wtest/westmere.pdf"
sudo rm -rf "$ALPINE/opt/wtest/node_modules/pdfjs-dist"
sudo cp -a "$PDFJS" "$ALPINE/opt/wtest/node_modules/pdfjs-dist"
sudo chmod -R a+rX "$ALPINE/opt/wtest" "$ALPINE/usr/local/bin/node26"
if ! mountpoint -q "$ALPINE/proc"; then sudo mount --bind /proc "$ALPINE/proc"; fi

echo "CPU=$CPU"
sudo chroot "$ALPINE" /usr/bin/qemu-x86_64-static -cpu "$CPU" /usr/local/bin/node26 /opt/wtest/test.mjs
