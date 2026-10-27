# homebrew test_app

Exercises the configured Homebrew formulae from tap `xberg-io/homebrew-tap` at the workspace release version.

| Formula     | Purpose                                                    |
| ----------- | ---------------------------------------------------------- |
| `ts-pack`   | CLI binary: tree-sitter language pack parser manager       |
| `libts-pack` | Shared library: C FFI for embedding in other languages    |

## Running

Install Bats with `brew install bats-core`, then run the generated launcher.

```bash
bash run_tests.sh
```

## What it tests

1. `brew bundle install` succeeds (tap + both formulae install without error).
2. `ts-pack --version` matches the workspace release version exactly.
3. `ts-pack --help` produces non-empty output.
4. Generated `ffi_smoke.c` compiles against `libts-pack` and checks its version function.
5. Consumer-owned `languages_smoke.c` checks that `ts_pack_available_languages` returns a list containing Python.
