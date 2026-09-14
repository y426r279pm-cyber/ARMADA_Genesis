#!/usr/bin/env bash
# Regenerating twice must produce the same bytes.
#
# The seed is built by running the prototype's own seed(), which uses
# crypto.randomUUID() and the wall clock. Left alone that gives a different
# 150-line file every run: the tree is always dirty, and a real change to the
# seed arrives buried in churn nobody reads. The harness pins both; this checks
# it stayed pinned.
set -euo pipefail
cd "$(dirname "$0")/.."

before=$(mktemp) && after=$(mktemp)
trap 'rm -f "$before" "$after"' EXIT

node tools/seed_harness.mjs >/dev/null
sha256sum Bridge/Sources/BridgeKit/Resources/Seed.json > "$before"
node tools/seed_harness.mjs >/dev/null
sha256sum Bridge/Sources/BridgeKit/Resources/Seed.json > "$after"

if ! diff -q "$before" "$after" >/dev/null; then
  echo "idempotency: FAILED — two runs of the seed harness disagree."
  echo "  Something in the sandbox is reading the clock or a real random source."
  echo "  See the determinism block in tools/seed_harness.mjs."
  exit 1
fi
echo "idempotency: the seed is byte-identical across runs"
