# n8n 2.48.5 overlay: replace only the Westmere-incompatible canvas binding.
#
# Base is the linux/amd64 image manifest, not the multi-arch index.
#   tag index  n8nio/n8n:2.48.5
#     sha256:c0ea1246a81a34ce8e2b3cfb1f718b97de64b0a1b3747ad24d6d431826bb71ad
#   linux/amd64 manifest (this FROM)
#     sha256:e169d448600a55b3ec74d4f9e622730d7e10653e0f13bf7331d3fbb559367d35
#   image config
#     sha256:df9d01105f92a0de18b194d5cdb7fefd68b2448d153b8ef15027f03acf2b9915
#
# Verified against Docker Hub on 2026-11-19:
#   Node 26.13.0-r1, Alpine 3.24, n8n 2.48.5, linux/amd64.
# docker.n8n.io is the same registry (auth realm registry.docker.io).
#
# Build from a directory that contains this Dockerfile and the rebuilt
# skia.linux-x64-musl.node (see /opt/cursor/artifacts).

FROM n8nio/n8n@sha256:e169d448600a55b3ec74d4f9e622730d7e10653e0f13bf7331d3fbb559367d35

COPY skia.linux-x64-musl.node \
  /usr/local/lib/node_modules/n8n/node_modules/@napi-rs/canvas-linux-x64-musl/skia.linux-x64-musl.node
