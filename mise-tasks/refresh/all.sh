#!/usr/bin/env bash
#MISE description="Update or upgrade every ecosystem, then report grammar updates and repin actions"
#MISE hide=true
#USAGE arg "<mode>" help="update stays within major versions; upgrade takes the latest, breaking ones included"
# shellcheck disable=SC2154 # usage_* are set by mise from the #USAGE lines
set -euo pipefail

mode="$usage_mode"
case "$mode" in
update | upgrade) ;;
*)
  echo "mode must be update or upgrade, got: $mode" >&2
  exit 2
  ;;
esac

for lang in rust python node wasm ruby go java csharp php elixir dart swift zig kotlin-android; do
  echo "Running $lang:$mode..."
  mise run "$lang:$mode"
done

# Grammar pins are NOT bumped automatically: a new pin makes `tree-sitter generate` execute that
# revision's grammar.js under Node, so every bump is arbitrary upstream code execution and needs
# human review. Report only; run `mise run update:grammars` explicitly to apply. ~keep
echo "Checking for language grammar updates (report only)..."
uv run --no-sync scripts/check_grammar_updates.py --dry-run
echo "Updating GitHub Actions pins..."
uvx --from gh-actions-updater gau --update --recursive --pin-style major --missing-ref fallback .github
