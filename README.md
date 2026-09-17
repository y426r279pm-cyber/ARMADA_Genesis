# Celebrity AI Companions — interactive wireframe v0.2

A single self-contained `index.html`: the tappable wireframe the concept deck
commits to at gate one ("Version 0.1 wireframe — specified, September 2026"),
extended by the v0.2 addendum. It runs offline, contacts nothing, and simulates
every service deterministically.

Open `index.html` in a browser. There is no build step, no dependency, and no
server.

| File | What it is |
| --- | --- |
| `index.html` | The prototype. Everything is inside it, including the SHA-256 implementation and every icon. |
| `ASSUMPTIONS.md` | Every unresolved decision, its default in this build, and who decides it. |
| `VERIFICATION.md` | The requirement-linked verification report, A01 to A27. |

---

## Scope of this version

This build implements `claude-build-requirements-v0.2-addendum.md` in full:
sections **D** (deck-driven changes), **R** (regulatory and safety), **K** (the
record), **L** (the rights model), and **V** (adapters and code structure), plus
acceptance scenarios A17 to A27.

**One caveat you should read before the report.** The addendum extends
`claude-build-requirements-v0.1.md`, and that file was not supplied with this
task. The v0.1 requirement IDs it tells us to preserve — S-01 to S-05, M-01 to
M-09, C-01 to C-06, T-01 to T-06, P-01 to P-06, and scenarios A01 to A16 — have
therefore been **reconstructed** from two sources that were supplied: the
addendum's own cross-references to them, and the concept deck, which states the
member journey, the plan rules, the rights model, and the platform guardrails
directly. Every reconstructed ID is listed in `VERIFICATION.md` with the
evidence it was reconstructed from. Where the real v0.1 says something
different, that document governs and this build should be corrected against it.

Nothing outside the addendum's scope was built. No 4K work, no high-fidelity
assets, no real identity, payment, inference, speech, avatar, social,
age-assurance, or record-anchoring service, and no hotline routing beyond the
sample card.

---

## Following the deck

The deck's narrative drives the build, not just its requirement list:

- **"A private conversation with the cast: licensed, disclosed, and always on."**
  Discover, the room, and the member controls are the three columns of deck
  page 2, in that order.
- **"Not a deepfake. Not unlicensed. Not unsupervised."** The About screen
  carries all three lines, and the product enforces them: the AI label is
  persistent, only `status === "approved"` personas exist publicly, and every
  managed-agent draft passes a human review queue.
- **"The personality approves. The member controls. The platform enforces."**
  One pure function, `effectiveBoundaries`, is the whole of that sentence, and
  the creator route has a debug view that shows which layer decided each topic.
- **"Unlimited is a promise about cost."** The Plans screen says so, and the
  Measurement panel computes the rented scenario beside the owned-rack scenario
  from the same event log — with the owned-rack unit left blank, because the
  deck says that number is measured in Phase 0, not asserted now.
- **"Five gates. If the number does not appear, there is no next step."**
  `LAUNCH_STATE = "prelaunch"` puts the waitlist where the conversation would
  be, because the gate-four number is paid conversion of a personality's
  waitlisted fans.
- **"Tom's company owns the brand, the roster, and the racks."** `OPERATOR` is
  the talent-side company; Armada appears only on About and the creator
  dashboard, never as a member-facing brand.

---

## The twelve-entry roster

Eleven personas are **invented** — fictional names, fictional taglines,
generated placeholder portraits, franchise tags drawn from the 90 Day family of
series. They exist to exercise the product, and each one says so on its own
detail screen.

The twelfth is **Big Ed (Ed Brown)**, carried as the deck's proposed
demonstration personality with rights status `pending` and the visible label
"Proposed, not licensed." He has no biography, no quotes, no storylines, no
approved boundary list, and no conversation. He does not appear in Discover. He
is a proposal, and the prototype says nothing about him that the deck does not.

Rights statuses are spread so the prototype exercises the whole P-01 lifecycle:
**1 pending, 8 approved, 2 expired, 1 revoked.**

---

## Walking through it in five minutes

1. Open the file. The tray at the bottom is the demo control surface: the
   simulated clock, `LAUNCH_STATE`, `billingChannel`, the disclosure interval,
   a seeded session, and reset.
2. **Seed a demo session.** One button runs a waitlist join, a signup, a Pro
   checkout, three days of conversation, and lands on Measurement with every
   figure labelled.
3. **Reset**, then walk it by hand: Discover → a companion → join the waitlist
   (prelaunch) → switch the tray to `live` → Plans → account and consent →
   checkout → the room.
4. In the room, try the **Demo intents** dropdown. It reaches every branch: a
   greeting, a question about the show, a memory recall, a talent-boundary
   crossing, a platform-restriction crossing, "are you really Ed?", a request
   for medical advice, and a crisis trigger.
5. Press **+1 hour** to cross the disclosure interval and see the reminder.
6. Go to **Creator → Precedence debug** to see which layer decided each topic,
   then **Creator → Roster** to revoke a persona and watch it leave Discover
   and turn its conversation read-only.
7. **Creator → Record** has a tamper tool. Alter an entry, and verification
   reports the first broken sequence number.

---

## How the file is organised

The file reads top to bottom in one pass:

| Block | Contents |
| --- | --- |
| Configuration | `OPERATOR`, `LAUNCH_STATE`, `PLANS`, `DISCLOSURE`, `COST_MODEL`, `BILLING_CHANNELS`, `PLATFORM_POLICY`, `TOPICS` |
| Fixtures | The roster, policies, demo intents, crisis triggers and resources, community posts |
| Strings | `STRINGS.en`, keyed by screen and element; `STRINGS.es` is deliberately empty |
| Core | SHA-256, canonical JSON, the seeded generator, the simulated clock, DOM helpers, generated portraits |
| State | The slices, persistence with a schema version and a migration stub, events, the record, the precedence engine, the entitlement reducers |
| Adapters | Eighteen boundaries, one shape each, every one `mode: "mock"` |
| Engine | The deterministic conversation engine, the disclosure cadence, the measurement computations |
| Screens | One function per screen, member then creator |
| Router | Hash routes, render, the rule self-checks, the seeded session, boot |

**Comment convention (T-04 as reconstructed).** Every block comment opens with
the requirement IDs it serves. Comments say *why* a rule exists, never what the
next line does. There is no commented-out code in the file.

### State slices

`session`, `member`, `entitlements`, `catalog`, `conversations`, `memories`,
`preferences`, `waitlist`, `record`, `events`, `policies`, `ui`, plus `safety`
and `moderation` for the R-section additions.

Entitlement transitions are pure reducers — `reduceSelectPlan`,
`reduceCheckoutSuccess`, `reduceCancel`, `reduceSelectCompanion`,
`reduceReleaseCompanion`, `reduceCountDay` — and are exercised by
`selfCheck()`, which runs at boot and renders its results on the About screen.

### Routes

`#/discover`, `#/companion/:id`, `#/plans`, `#/account`, `#/profile`,
`#/checkout`, `#/companions`, `#/conversation/:id`, `#/community`,
`#/settings`, `#/waitlist` (and `#/waitlist/:id`), `#/creator`,
`#/creator/measurement`, plus `#/about`.

### The record

Append-only, hash-chained with an embedded SHA-256 over the canonical JSON of
each entry plus `prevHash`. Payloads carry identifiers, versions, and statuses
only — never message text, images, or private interests. `Record.verify()`
returns the first broken sequence number, or `null`.

Deleting a conversation, a memory, or the account removes the content and
leaves a tombstone carrying identifiers and hashes only, so the chain still
verifies after erasure. The copy says it plainly: the record proves that
something happened and when, not what was said.

### Adapters

```
auth  catalog  billing  inference  speech  avatar  images  memory  consent
safety  ageAssurance  record  agents  social  analytics  waitlist  reports
licenses
```

Each declares `mode: "mock"`, its proposed contracts (method, input, output,
expected errors, authorisation, sensitive fields, intended caller), and a
`production` note stating where the real implementation runs — `rack` for
inference, speech, memory, the record, and safety screening; `vendor` for
identity, payments, age assurance, and store billing. The full table renders at
the bottom of **Creator → Measurement**.

---

## Console handle

`window.__wireframe` exposes `state()`, `adapters`, `Record`,
`effectiveBoundaries`, `measure()`, `selfCheck()`, `Clock`, `reset()`,
`seedDemoSession()`, `render()`, `go()`, and `routes`.

---

## Build hygiene

- No external font, script, or stylesheet. No network call of any kind.
- SHA-256 and every icon are inline. Portraits are generated SVG, not files.
- `index.html` is about 284 KB, well under the 1.5 MB ceiling.
- Formatted with Prettier (printWidth 100) and linted with ESLint: **zero
  errors**; the only warnings are three intentionally unused `catch (e)`
  bindings around storage access, which must not throw.
- User content is written with `textContent` only. `innerHTML` is used in
  exactly three places, all with literal inline SVG that carries no user data.

## Known limits

- `STRINGS.es` is empty on purpose; localisation is a later phase and a missing
  key falls back to English so the gap is visible in review.
- Retention in Measurement reads across a single prototype member, so it is 1
  or 0 rather than a rate. The "Sample data" label is the honest part.
- The crisis screen is a fixture phrase list, not a classifier. It will miss
  real phrasing, which is exactly why production runs a real screen on the rack.
