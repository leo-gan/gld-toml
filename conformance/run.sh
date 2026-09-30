#!/usr/bin/env bash
# Run the official toml-test v2.2.0 harness when the binary is installed.
# Exit 0 when the binary is absent so CI without Go still passes.
# The in-repo suite is tests/test_suite.mojo.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
if ! command -v toml-test >/dev/null 2>&1; then
  echo "toml-test not on PATH; skipping official harness"
  exit 0
fi
if command -v pixi >/dev/null 2>&1; then
  MOJO=(pixi run mojo)
else
  MOJO=(mojo)
fi
dec="$(mktemp)"
enc="$(mktemp)"
trap 'rm -f "$dec" "$enc"' EXIT
"${MOJO[@]}" build -I src conformance/decoder.mojo -o "$dec"
"${MOJO[@]}" build -I src conformance/encoder.mojo -o "$enc"
toml-test test -toml 1.1 -decoder "$dec" -encoder "$enc"
