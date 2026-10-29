#!/usr/bin/env bash
#MISE description="Build the ts-pack-core-ffi library with grammars linked statically"
#MISE hide=true
#MISE env={FFI_TEST_LANGUAGES="{{vars.ffi_test_languages}}"}
#USAGE flag "--dev" help="Build the debug profile instead of release"
#USAGE flag "--languages <list>" help="Comma-separated grammars to compile in (default: the FFI test set)"
# shellcheck disable=SC2154 # usage_* are set by mise from the #USAGE lines
set -euo pipefail

profile=(--release)
if [ "${usage_dev:-false}" = true ]; then profile=(); fi
TSLP_LINK_MODE=static TSLP_LANGUAGES="${usage_languages:-$FFI_TEST_LANGUAGES}" \
  cargo build ${profile[@]+"${profile[@]}"} --locked -p ts-pack-core-ffi
