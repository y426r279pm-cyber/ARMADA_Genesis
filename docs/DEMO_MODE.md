---
title: Bridge™ Swift · The client build
audience: Internal, Armada. Engineering note.
prepared_by: Taylor, for M. David King
date: 2026-09-14
status: Built. Verify before every client session.
---

# What the rule is

Daniel's section 7: no node counts, no model names, no bill of materials, no
prices, before a signed discovery agreement. RC1 broke four of those on five
screens. RC2 answers with a demo mode.

# Why it is a build and not a switch

A runtime toggle has two problems, and the second is the serious one.

It can be flipped. A toggle sits one control away from a screen and one mistake
away from a room, and the room in question is the one the Discovery depends on.

And it does not remove anything. With a toggle, "Kimi shard" is still in the
bundle — in `Seed.json`, in a string table, in a crash log, in a screenshot of a
screen that rendered before the flag was read, in an unzipped `.app` that anyone
can open. Hiding a name is not the same as not shipping it, and the rule is about
what leaves the building.

So the client build removes both the data and the code paths.

# The two steps

    tools/make_client_build.sh

**1 · The seed is replaced.** `tools/redact_seed.py` produces
`Seed.client.json`: node roles become "escalation model shard" and "routine
model", and no model family name survives anywhere in the file. The script
verifies its own output before writing and fails rather than emitting a leaky
file. Record counts, ids and relationships are unchanged, so every screen renders
identically — the client sees the real console, not a smaller one.

**2 · The binary is compiled with `-DCLIENT_DEMO`.** `DemoMode.isClientBuild`
becomes a compile-time constant, so the branches that would print a node count or
a price are not in the shipped binary. Configuration, the model catalogue and the
Installer are not routable at all.

Either step alone is a half measure. The flag without the seed swap ships the
names in a resource. The seed swap without the flag ships screens that would
print them the moment real data arrived.

# What the audit checks

`DemoModeTests` runs against the shipped files, not a running app:

| Test | What it stops |
|---|---|
| No forbidden name in `Seed.client.json` | a name reaching the bundle |
| The internal seed *does* contain them | a redactor that passes by emptying the file |
| Record counts match between the two seeds | a client demo that is quietly a smaller product |
| Node roles are neutral and non-empty | a blank role that reads as missing data |
| `nodeCount` returns "the rack", never a number | a vaguer count, which is still a count |
| Hidden screens are absent, not empty | an emptied screen inviting the question |
| The seed resource follows the build flag | the two steps drifting apart |

Run it before every client session:

    swift test --package-path Bridge --filter DemoModeTests

# What is deliberately still shown

**Power in kilowatts.** Section 7 allows it and forbids only appliance
comparisons. The Energy screens comply already.

**Every figure labelled.** "Sample data" and "to be measured" appear in both
builds. The rule is about not showing a result before one is measured, and that
applies internally too — a seeded figure that looks measured is just as
misleading to us.

**The honest limits.** The Audit screen's statement of what a seal does and does
not prove is in both builds. It is not a disclosure risk; it is the product's
actual claim, and softening it for a client would be the wrong direction.

# What this does not cover

The 4 template-literal strings noted in `docs/STRING_CONFLICTS.md` are hand
ported and should be re-read against section 7 when they are.

Anything typed into the console during a demo — a case note, a chat question —
is not redacted, because it is the client's own material. If a demo is given on a
machine holding internal records, that is a different problem and this build does
not solve it: use a clean store.
