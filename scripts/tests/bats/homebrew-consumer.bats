# shellcheck shell=bash

setup() {
	bats_load_library xberg-bats
	xberg_setup
	ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd -P)"
	SCRIPT="$ROOT/test_apps/homebrew/run_tests.sh"
	export REPORTED_VERSION
	REPORTED_VERSION="$(sed -n 's/^version = "\([^"]*\)"/\1/p' "$ROOT/Cargo.toml" | head -n 1)"
	[ -n "$REPORTED_VERSION" ]
	xberg_stub brew 'case "$1" in --prefix) printf "%s\n" "$XBERG_WORK/prefix";; esac'
	xberg_stub pkg-config 'exit 1'
	xberg_stub ts-pack \
		'case "$1" in --version) printf "%s %s\n" "ts-pack" "$REPORTED_VERSION"; exit "${CLI_STATUS:-0}";; --help) printf "Usage: ts-pack\n";; *) exit 2;; esac'
	xberg_stub cc \
		'printf "%s\n" "$*" >> "$XBERG_TRACE"' \
		'message="PASS: version returned: valid"' \
		'case "$*" in *languages_smoke.c*) message="PASS: ts_pack_available_languages returned: python";; esac' \
		'while [[ $# -gt 0 ]]; do if [[ "$1" == -o ]]; then destination="$2"; break; fi; shift; done' \
		'printf "#!/usr/bin/env bash\nprintf '\''%%s\\n'\'' '\''%s'\''\n" "$message" > "$destination"' \
		'chmod +x "$destination"'
}

@test "generated Homebrew suite collects 4 checks and executes every command" {
	run bats --count "$ROOT/test_apps/homebrew/homebrew.bats"
	xberg_assert_status 0
	xberg_assert_output 4
	run bash "$SCRIPT"
	xberg_assert_status 0
	xberg_assert_output_contains '1..4'
	xberg_assert_output_contains 'ok 1 cli-version'
	xberg_assert_output_contains 'ok 2 cli-help'
	xberg_assert_output_contains 'ok 3 ffi-language-list'
	xberg_assert_output_contains 'ok 4 ffi-smoke'
	run cat "$XBERG_TRACE"
	xberg_assert_output_contains 'languages_smoke.c'
	xberg_assert_output_contains 'ffi_smoke.c'
}

@test "generated Homebrew suite rejects another installed release" {
	export REPORTED_VERSION=0.0.0
	run bash "$SCRIPT"
	xberg_assert_status 1
	xberg_assert_output_contains 'not ok 1 cli-version'
}

@test "generated Homebrew version pipeline propagates a failed CLI status" {
	export CLI_STATUS=7
	run bash "$SCRIPT"
	xberg_assert_status 1
	xberg_assert_output_contains 'not ok 1 cli-version'
}
