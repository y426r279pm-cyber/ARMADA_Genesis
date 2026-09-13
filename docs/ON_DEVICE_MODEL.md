---
title: Bridge™ Swift · Taylor on the device · model and memory budget
audience: Internal, Armada. Engineering note.
prepared_by: Taylor, for M. David King
date: 2026-09-13
status: Recommendation. Measure on the actual machine before the CEO conversation.
---

# The constraint

The demo runs on a 16 GB Apple silicon Mac. Unified memory means the model
competes with everything else on the machine, so the budget is not "16 GB minus
the weights" — it is what is left after macOS, the window server, Bridge itself,
and whatever else is open on the day.

| Claim on memory | Working figure |
|---|---|
| macOS and WindowServer, idle | 4–5 GB |
| Bridge: SwiftUI, SwiftData, the seeded store | under 1 GB |
| Whatever else is open (a browser, Keynote, Slack) | 1–3 GB, and nobody closes these under pressure |
| **Left for weights and KV cache** | **7–9 GB, and the low end is the one to plan for** |

Spending the whole headroom is the wrong instinct. On 16 GB the failure mode is
not a refusal to load; it is memory pressure, compression, then swap — which
looks like Bridge going unresponsive mid-sentence, in front of the person the
Discovery depends on.

# Recommendation

**Qwen 2.5 7B Instruct, 4-bit, roughly 4.2 GB of weights.** Approximately, and
worth measuring: the figure is 7.6B parameters at 4 bits plus embeddings and
overhead, not a number read off a spec sheet.

Three reasons.

**It keeps the prototype's model.** RC2.1 already runs Qwen 2.5 through WebLLM,
so this is the port staying faithful rather than making a new choice. Answers
should read the same.

**It leaves real headroom.** 4.2 GB of weights against a 7–9 GB budget leaves
room for the KV cache to grow through a long conversation and for the machine
to have a bad day. A 14B at 4-bit is around 8 GB and eats the entire budget.

**Nobody sees the name.** Daniel's section 7 forbids model names in client
material, and RC2's demo mode shows "routine model" and "escalation model"
instead. The model is judged on its answers, not its parameter count — which
means reliability is worth more here than the last few points of quality.

Carry **Qwen 2.5 3B at 4-bit (~1.7 GB)** as the fallback, selectable in Settings.
Not as a lesser option but as the one that runs when the machine is already
loaded. A smaller model that answers beats a larger one that swaps.

# What this changes in the build

**Pre-cache the weights. Never download during a demo.** The prototype fetches
on "Bring Taylor in" and caches; that is right for a browser prototype and wrong
for this. Ship the weights beside the app or pre-warm the cache, and have the
first run be a deliberate, supervised step days earlier.

**Load at launch, not at first message.** Moving several gigabytes from disk into
unified memory takes seconds. Those seconds must be spent while somebody is still
talking about the architecture, not after a question has been asked.

**Pre-flight the machine.** A short check on launch — available memory, model
present, thermal state — surfaced in Settings. If the machine cannot carry the
7B today, fall back to the 3B before the demo rather than during it.

**Thermals, if this is a MacBook Air.** Fanless hardware throttles under
sustained inference, and a demo is exactly sustained inference. On an Air, plan
for the 3B, or accept that the third and fourth answers arrive slower than the
first. On a Pro or a mini this does not arise.

# The honest framing

The demo Mac is a stand-in. Génesis is a rack, and the argument is that the model
runs on hardware the institution owns, not that it runs on a laptop. What the
laptop has to prove is that the answers are real, local, and fast enough to hold
a conversation. A 7B at 4-bit does that. Reaching for more risks the one thing
the demo cannot survive, which is stalling.
