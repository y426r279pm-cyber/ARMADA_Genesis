#!/usr/bin/env bash
# Regenerate every extracted artefact from source/Bridge_RC2_1.html.
# Run from the repository root. Order matters: the schema is inferred from the
# seed, so the seed harness runs first.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== scanner tests =="
python3 tools/test_jsscan.py

echo; echo "== extract =="
python3 tools/extract_tokens.py
python3 tools/extract_routes.py
python3 tools/extract_roles.py
python3 tools/extract_strings.py
python3 tools/extract_icons.py
node    tools/seed_harness.mjs
python3 tools/extract_schema.py
python3 tools/redact_seed.py

echo; echo "== checks =="
python3 tools/check_strings.py
bash    tools/check_idempotent.sh

echo; echo "== chain =="
python3 tools/verify_chain.py

echo; echo "Done. Generated files are under Bridge/Sources/BridgeKit/."
