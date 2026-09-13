#!/usr/bin/env python3
"""
Proves what the chain hashes, and what breaks it.

This is the conversion plan's largest risk, settled with evidence rather than
argument. The prototype seals with:

    payload = JSON.stringify({ es, en, actor, ...extra })
    hash    = sha256((prev ? prev.hash : "genesis") + at + actor + payload)

JSON.stringify emits keys in *insertion order*. Swift's JSONEncoder emits them
sorted or in declaration order, and formats numbers differently. So the
question is not whether Swift can compute SHA-256 — it is whether Swift can
reproduce this exact byte sequence. This script reconstructs the payload two
ways against the real seeded ledger and shows which one verifies.
"""

import hashlib, json, sys

SEED = "Bridge/Sources/BridgeKit/Resources/Seed.json"
RESERVED = ("id", "seq", "at", "actor", "es", "en", "prevHash", "hash")


def js_stringify(obj):
    """JSON.stringify for the value shapes the ledger uses.

    Insertion order, no spaces, and JavaScript's number formatting: an integral
    float prints without its fractional part."""
    if obj is True:
        return "true"
    if obj is False:
        return "false"
    if obj is None:
        return "null"
    if isinstance(obj, str):
        return json.dumps(obj, ensure_ascii=False)
    if isinstance(obj, (int, float)):
        if isinstance(obj, float) and obj.is_integer():
            return str(int(obj))
        return repr(obj)
    if isinstance(obj, list):
        return "[" + ",".join(js_stringify(v) for v in obj) + "]"
    if isinstance(obj, dict):
        return "{" + ",".join(f"{json.dumps(k, ensure_ascii=False)}:{js_stringify(v)}"
                              for k, v in obj.items()) + "}"
    raise TypeError(type(obj))


def payload_insertion_order(entry):
    """{ es, en, actor, ...extra } — the order the prototype writes."""
    out = {"es": entry["es"], "en": entry["en"], "actor": entry["actor"]}
    for k, v in entry.items():
        if k not in RESERVED:
            out[k] = v
    return js_stringify(out)


def payload_sorted_keys(entry):
    """What a naive Swift JSONEncoder(.sortedKeys) would produce."""
    out = {"es": entry["es"], "en": entry["en"], "actor": entry["actor"]}
    for k, v in entry.items():
        if k not in RESERVED:
            out[k] = v
    return json.dumps(out, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def verify(chain, payload_of):
    prev = "genesis"
    for e in chain:
        digest = hashlib.sha256((prev + e["at"] + e["actor"] + payload_of(e)).encode()).hexdigest()
        if e["prevHash"] != prev or digest != e["hash"]:
            return False, e["seq"]
        prev = e["hash"]
    return True, len(chain)


def main():
    with open(SEED, encoding="utf-8") as fh:
        chain = sorted(json.load(fh)["ledger"], key=lambda e: e["seq"])
    if not chain:
        raise SystemExit("no ledger in the seed; run tools/seed_harness.mjs first")

    print(f"chain: {len(chain)} entries from the prototype's own seal()\n")
    ok_ins, at_ins = verify(chain, payload_insertion_order)
    ok_srt, at_srt = verify(chain, payload_sorted_keys)

    print(f"  insertion order (what the prototype writes) : {'VERIFIES' if ok_ins else f'BREAKS at seq {at_ins}'}")
    print(f"  sorted keys (a naive JSONEncoder)           : {'VERIFIES' if ok_srt else f'BREAKS at seq {at_srt}'}")

    sample = chain[0]
    print(f"\n  seq 1 payload, insertion order:\n    {payload_insertion_order(sample)}")
    print(f"  seq 1 payload, sorted keys:\n    {payload_sorted_keys(sample)}")

    if not ok_ins:
        print("\nThe insertion-order reconstruction does not verify. Either the seal rule has")
        print("changed or this script has drifted from it. Fix before porting the chain.")
        return 1
    if ok_srt:
        print("\nBoth forms verify, which means this seed happens to carry no entry whose key")
        print("order differs from sorted. The risk is still real for entries that do — keep")
        print("the canonical encoder. Add a seeded entry with out-of-order extras to prove it.")
        return 0
    print(f"\nBoth results are the point. The chain verifies only under insertion-order")
    print(f"serialisation; a sorted-key encoder breaks it at seq {at_srt}, and the break")
    print("reads as tampering rather than as a serialisation difference.")
    print("\nFor Swift: seal through a canonical encoder that writes { es, en, actor } first,")
    print("then extras in insertion order, with no whitespace and JavaScript number")
    print("formatting. Do not use JSONEncoder for the sealed payload.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
