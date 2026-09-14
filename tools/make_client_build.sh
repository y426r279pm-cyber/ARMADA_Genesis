#!/usr/bin/env bash
# Build the client demo.
#
# Two steps, both of which matter:
#   1. swap the seed for the redacted one, so the model names are not in the
#      bundle at all;
#   2. compile with -DCLIENT_DEMO, so the branches that would show a node count
#      or a price are not in the binary.
#
# Either alone is a half measure. A flag without the seed swap ships the names in
# a resource; a seed swap without the flag ships screens that would print them if
# the data came back.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== redact =="
python3 tools/redact_seed.py

echo
echo "== swap the seed =="
cp Bridge/Sources/BridgeKit/Resources/Seed.json /tmp/Seed.internal.json
cp Bridge/Sources/BridgeKit/Resources/Seed.client.json Bridge/Sources/BridgeKit/Resources/Seed.json
restore() {
  cp /tmp/Seed.internal.json Bridge/Sources/BridgeKit/Resources/Seed.json
  echo "internal seed restored"
}
trap restore EXIT
echo "client seed in place"

echo
echo "== build =="
swift build --package-path Bridge -c release \
  -Xswiftc -DCLIENT_DEMO \
  "$@"

echo
echo "Client build complete. The internal seed is restored on exit."
echo "Verify before shipping:  swift test --package-path Bridge --filter DemoModeTests"
