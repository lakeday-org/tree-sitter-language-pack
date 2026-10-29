#!/usr/bin/env bash
#MISE description="Generate the flutter_rust_bridge glue and build the Dart package's Rust crate"
#MISE hide=true
#USAGE arg "<profile>" help="release or dev"
# shellcheck disable=SC2154 # usage_* are set by mise from the #USAGE lines
set -euo pipefail

case "$usage_profile" in
release) profile=(--release) ;;
dev) profile=() ;;
*)
  echo "profile must be release or dev, got: $usage_profile" >&2
  exit 2
  ;;
esac
command -v dart >/dev/null 2>&1 || {
  echo "dart is required on PATH" >&2
  exit 1
}
command -v flutter_rust_bridge_codegen >/dev/null 2>&1 ||
  cargo install --locked flutter_rust_bridge_codegen --version 2.12.0
(cd packages/dart && dart pub get)
(cd packages/dart/rust && flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge.yaml)
TSLP_LINK_MODE=static TSLP_LANGUAGES=mojo,nim,norg \
  cargo build ${profile[@]+"${profile[@]}"} --locked -p tree-sitter-language-pack-dart
(cd packages/dart && dart pub get)
