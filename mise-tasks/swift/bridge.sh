#!/usr/bin/env bash
#MISE description="Build the swift-bridge Rust crates and wire their generated sources into packages/swift"
#MISE hide=true
#USAGE arg "<profile>" help="release or debug"
# shellcheck disable=SC2154 # usage_* are set by mise from the #USAGE lines
set -euo pipefail

case "$usage_profile" in
release) profile=(--release) ;;
debug) profile=() ;;
*)
  echo "profile must be release or debug, got: $usage_profile" >&2
  exit 2
  ;;
esac
command -v swift >/dev/null 2>&1 || {
  echo "swift is required on PATH" >&2
  exit 1
}
TSLP_LINK_MODE=static TSLP_LANGUAGES=mojo,nim,norg \
  cargo build ${profile[@]+"${profile[@]}"} --locked -p tree-sitter-language-pack-swift -p ts-pack-core-ffi
bash scripts/setup-swift-bridge.sh "$usage_profile"
