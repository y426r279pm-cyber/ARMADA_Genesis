# Verification report — Celebrity AI Companions wireframe v0.2

Build: single self-contained `index.html`, 284 KB, no network, no dependency.
Verified: 2026-09-17.

## How this was verified

Every result below was produced by driving the real file in a real browser
(Chromium via Playwright), not by reading the code. The driver clicks the
actual controls, reads the actual DOM, and inspects the actual state and record
after each step. Two further passes ran alongside it:

- **ESLint** over the whole script: **0 errors**, 3 warnings, all of them
  intentionally unused `catch (e)` bindings around storage access.
- **Prettier** (printWidth 100) as the final formatting pass; the acceptance
  suite was re-run afterwards and still passes.
- **Console watch** across the entire run: no uncaught page error, no
  `console.error`.

The prototype also carries eleven of its own rule self-checks over the pure
entitlement, precedence, and record functions. They run at boot and render on
the **About** screen. All eleven pass.

**No screenshot or test output has been invented.** Where a scenario is marked
passed, the driver asserted it.

---

## ⚠️ A necessary caveat on v0.1

The addendum extends `claude-build-requirements-v0.1.md`. **That file was not
supplied with this task.** The IDs the addendum tells us to preserve — S-01 to
S-05, M-01 to M-09, C-01 to C-06, T-01 to T-06, P-01 to P-06, and scenarios
A01 to A16 — have therefore been **reconstructed** from the only two sources
that were supplied:

1. The addendum's own cross-references, which pin ten of them precisely: M-02
   (consent screen), M-03 (18-plus checkbox), M-04 (mature-content
   preferences), M-09 (data export), S-04 (cancellation flow), S-05 (the
   unlimited claim), C-05 (agent approvals), T-03 (reset, text nodes), T-04
   (comment convention), T-05 (adapter registry), P-01 (rights statuses), P-04
   (counsel-approved policy copy), P-05 (no subscription pressure in
   conversation), P-06 (aggregate insights only).
2. The concept deck, which states the eight-step member journey (page 6), the
   three plan rules (page 7), and the six-line talent licence and seven-line
   platform guardrails (page 8) directly.

**Everything in the A01–A16 block below is therefore a reconstruction, not the
original scenario list.** It is reported as such. If the real v0.1 says
something different, that document governs and this build should be corrected
against it. A17 to A27 are the addendum's own scenarios, quoted as written, and
carry no such caveat.

---

## Acceptance scenarios

### A17–A27 — from the addendum, as written

| ID | Scenario | Result | Evidence from the run |
| --- | --- | --- | --- |
| **A17** | Set `LAUNCH_STATE` to prelaunch, open a companion, join the waitlist | **passed** | `waitlist_join` event recorded keyed to `marisol-vega`; count 612 → 613; contact consent and marketing consent stored separately (true / false); "Sample data" label shown; switching the tray to `live` routed the same action to `#/plans` |
| **A18** | Start a conversation, advance the demo clock past the disclosure interval | **passed** | Opening notice present verbatim; after +1 hour a reminder appeared, was logged once to the transcript and once to the record (`ai_disclosure_reminder`), the composer stayed enabled throughout, and Dismiss removed it |
| **A19** | Send a fixture crisis trigger phrase | **passed** | Companion paused (composer removed); resources card with the 988 Lifeline and "Talk to a person" shown; card states it cannot provide therapy or medical advice; record entry payload keys were exactly `action, category, conversationId, messageTextStored`, and the phrase appears nowhere in the serialised record; persona resumed only after dismissal |
| **A20** | Report a response, then block the companion | **passed** | Ticket `TCK-1001` confirmed and visible in Settings → Safety; companion gone from both My companions and Discover; unblock restored it; 14 messages retained through the block |
| **A21** | In the creator route, change an approved persona to revoked with a note | **passed** | Apply without a note was refused; after the note, the persona left Discover and the slot count, its open conversation turned read-only, `license_status_changed` carried the note and the actor, and `Record.verify()` returned `null` |
| **A22** | Alter a record entry through the debug tool, then verify | **passed** | `Record.verify()` returned `2`, the panel reported "The chain is broken from sequence 2", and reset restored `null` |
| **A23** | Enable mature themes, talk to a persona whose boundaries exclude them, then to one that allows them | **passed** | Dax Holloway replied with the talent-layer refusal naming him; Marisol Vega answered in role; the platform-restricted request returned the platform-layer refusal for both |
| **A24** | Bump a policy version in fixtures and revisit | **passed** | Privacy Notice 1.1 → 1.2 forced a renewed acknowledgment that blocked every route until acknowledged; the record holds `policy_version_changed` (1.1 → 1.2) and `consent_accepted` at both 1.1 and 1.2; chain verified |
| **A25** | Run the seeded session and open Measurement | **passed** | Landed on `#/creator/measurement` with conversion per personality (2 joins, 1 paid, 50.0%), active minutes per member per day, messages per session, distinct companions per member per day, 7-day retention reached and 30-day "not reached yet", and rented versus owned-rack cost. Every figure labelled "Sample data" or "Estimate, to be measured in Phase 0"; blank unit assumptions render as "not measured", never as a guessed number |
| **A26** | Delete the account, reload, verify the record | **passed** | Profile, conversations, and memories gone and still gone after a reload; 12 record entries retained including 2 tombstones; `Record.verify()` returned `null`; no personal text (name, email, or memory content) remained anywhere in the chain |
| **A27** | Attempt to enable mature preferences while age assurance is unverified | **passed** | Both mature switches disabled with the explanation "Mature preferences need a verified age"; after the demo check, 0 disabled and both subject to L-02 |

### A01–A16 — reconstructed from the deck and the addendum's cross-references

| ID | Reconstructed scenario | Result | Evidence from the run |
| --- | --- | --- | --- |
| **A01** | Discover lists approved personalities only, with AI labels and a working franchise filter | **passed (reconstructed)** | 8 of 12 shown, 8 AI labels, 8 approved badges, Big Ed absent; filtering to "The Other Way" returned exactly Priya Raman and Tobias Lindqvist |
| **A02** | Companion detail shows supported modes and approved boundaries; the proposed entry shows no approval language | **passed (reconstructed)** | Marisol Vega: modes and "What Marisol Vega approved" present. Big Ed: "Proposed, not licensed" only, no approval language, no biography |
| **A03** | Plans show exact prices, flag the Expanded assumption, and gate the unlimited claim | **passed (reconstructed)** | US$6.95 / US$14.95 / US$29.95 all present; "Prototype assumption, not an approved entitlement" on Expanded; "Unlimited is a promise about cost" on the screen |
| **A04** | Account creation needs every acknowledgment, unchecked by default, plus the 18-plus gate, and records the version | **passed (reconstructed)** | 7 checkboxes, all unchecked on arrival; submit refused with "Every acknowledgment is required" until all were ticked; 7 `consent_accepted` entries written with policy ids and versions |
| **A05** | Content preferences are off by default and nothing is published by a profile action | **passed (reconstructed)** | Every member topic initialised to `false`; screen carries "Private by default" and "never published" |
| **A06** | Simulated checkout states renewal, collects no card details, and handles failure and success | **passed (reconstructed)** | No card input exists on any channel; renewal date shown; the simulated failure left status `pending_checkout` and wrote `checkout_fail`; the success wrote `checkout_success` attributed to `marisol-vega` |
| **A07** | My companions shows the plan indicator and keeps a separate conversation per companion | **passed (reconstructed)** | Pro day counter rendered; 2 conversations across 2 distinct personalities, no shared history |
| **A08** | The room carries the AI notice and persistent label, answers text, cycles the simulated voice states, and shares a still image | **passed (reconstructed)** | Opening notice verbatim; 1 persistent AI badge in the header; voice cycled idle → listening → processing → speaking with one `voice_utterance`; still image shared, no audio captured |
| **A09** | A returning member signs in and goes straight to My companions | **passed (reconstructed)** | After a reload the session, entitlements, conversations, and record all restored; the account screen shows the signed-in state and routes onward |
| **A10** | Memory is saved, recalled, inspectable and editable per companion, and deletion leaves no text | **passed (reconstructed)** | "Saved to memory" shown; the recall reply quoted the saved item; memory held by Kenji Alvarez only; delete-all left a `memory_deleted` tombstone and no text in the record |
| **A11** | Entry refuses a fifth selection while four are held | **passed (reconstructed)** | In-file reducer self-check S-01, run in the browser |
| **A12** | Pro counts seven distinct personalities a day and refuses the eighth, reset on a provisional UTC day | **passed (reconstructed)** | In-file reducer self-check S-03, run in the browser |
| **A13** | Cancellation keeps access to the period end, carries no retention pressure, and the companion never mentions the subscription | **passed (reconstructed)** | No appeal, countdown, or loss language in the flow; one optional reason question; `accessUntil === renewsAt`; no companion message in any conversation matched subscription, renewal, cancellation, plan, or billing |
| **A14** | The data export contains profile, conversations, memories, and the member record, and is itself recorded | **passed (reconstructed)** | Export parsed as JSON with all four sections and 6 record entries; a `data_exported` entry was written |
| **A15** | The roster exercises all four rights statuses, the operator token renders visibly, and Armada appears only where allowed | **passed (reconstructed)** | 1 pending / 8 approved / 2 expired / 1 revoked; `{{COMPANY_NAME}}` rendered as a visible token; "Technology by Armada" present on About and the creator dashboard, absent from member screens |
| **A16** | Reset clears every slice and reseeds the fixtures | **passed (reconstructed)** | Record and conversations empty, no member events left (only the one `screen_view` the reload itself records); signed out; 12 personas reseeded; chain verifies |

**Summary: 27 of 27 passed. 0 failed. 0 unverified.** A01–A16 passed against the
reconstruction described above, not against the original v0.1 text.

---

## Requirement coverage

### D — Deck-driven changes (addendum)

| ID | Where it lives | Status |
| --- | --- | --- |
| D-01 | `OPERATOR` config; `companyToken()`; About, legal footer, consent entries, receipts, export, creator dashboard | implemented — token renders visibly; Armada confined to About and the creator route (A15) |
| D-02 | `ROSTER` — 11 invented personas + Big Ed at `pending` with "Proposed, not licensed"; 1/8/2/1 status spread | implemented (A01, A02, A15) |
| D-03 | `LAUNCH_STATE`, `#/waitlist`, `adapters.waitlist`, fixture counts labelled "Sample data" | implemented (A17) |
| D-04 | `EVENT_TYPES` (all 14), `track()`, `measure()`, `#/creator/measurement` | implemented (A25) — all 14 types are emitted by the running app; a coverage pass confirmed 12 of 14 during the seeded session, the other two (`checkout_fail`, `cancel`) in A06 and A13 |
| D-05 | `COST_MODEL`, rented vs owned-rack table, deck's worked example beside it | implemented (A25) — owned-rack unit deliberately blank |
| D-06 | `BILLING_CHANNELS`, checkout summary copy, tray switch | implemented (A06) — identical prices, no card form, no store integration |

### R — Regulatory and safety layer

| ID | Where it lives | Status |
| --- | --- | --- |
| R-01 | Opening notice, persistent header label, recurring reminder, `DISCLOSURE` config | implemented (A08, A18) |
| R-02 | `adapters.safety.screen`, `crisisCard()`, `CRISIS_RESOURCES` | implemented (A19) — fixture phrase list, declared as such |
| R-03 | `adapters.ageAssurance`, Settings state display, mature-preference lock | implemented (A27) |
| R-04 | `openReport()`, `adapters.reports.file/block`, Settings → Safety | implemented (A20) — all five categories present |
| R-05 | `POLICIES` registry, Settings policy table, `pendingPolicyGate()` | implemented (A24) |
| R-06 | `openCancel()` | implemented (A13) |

### K — The record

| ID | Where it lives | Status |
| --- | --- | --- |
| K-01 | `Record.append/verify`, embedded `SHA256`, `canonicalJSON`; all 11 entry types | implemented (A21, A22) — a coverage pass confirmed every one of the 11 entry types is written by a real path, with the chain still verifying |
| K-02 | Settings → "Your record"; included in the export | implemented (A14, A26) |
| K-03 | Creator → Rights timeline; agent approvals; no member entries on the route | implemented (A21) |
| K-04 | Tombstones on memory, conversation, and account deletion | implemented (A10, A26) |

### L — The rights model

| ID | Where it lives | Status |
| --- | --- | --- |
| L-01 | `lic()` scope object; Creator → Rights (read-only); "What [name] approved" vs "Proposed, not licensed" | implemented (A02) — badges render from `status` only |
| L-02 | `effectiveBoundaries()`; consulted by text, voice, and image paths; Creator → Precedence debug | implemented (A23) + self-checks L-02a/b/c |
| L-03 | `availabilityOf()`, `sweepExpiries()`, `applyAvailabilityToConversations()` | implemented (A21) — clock-reachable expiry |
| L-04 | Creator metrics derive from `events[]` only; copy states it | implemented (A25) |

### V — Adapters and code structure

| ID | Where it lives | Status |
| --- | --- | --- |
| V-01 | 18 adapters, uniform shape, all 7 new proposed contracts present | implemented — full table renders on Measurement |
| V-02 | One `state` with the named slices; pure reducers with self-checks; one render function per screen behind a hash router; `schemaVersion` + migration stub; one reset | implemented (A11, A12, A16) |
| V-03 | Seeded generator, simulated clock with +1 hour / +1 day / +30 days, one `FIXTURES` object, all six required demo intents plus three more | implemented |
| V-04 | `STRINGS.en` keyed by screen and element; `STRINGS.es` empty; text nodes only | implemented — see note below |
| V-05 | No external font, script, or stylesheet; inline SHA-256 and SVG; 283 KB; Prettier + ESLint clean; T-04 comment convention | implemented |

**One deviation to flag on V-04.** UI chrome copy lives in `STRINGS.en` as
required. Fixture *content* — persona taglines, policy summaries and outlines,
community posts, crisis resource text — lives in `FIXTURES` instead, because it
is data a reviewer edits as data, not chrome. Both are localisable the same way.
If v0.1 intends every last string in `STRINGS.en`, this is the change to make.

### v0.1 requirements (as reconstructed)

| Group | Reconstructed as | Status |
| --- | --- | --- |
| S-01 / S-02 / S-03 | Entry, Expanded, Pro plan rules | implemented (A03, A11, A12) |
| S-04 | Cancellation, access to period end | implemented (A13) |
| S-05 | "Unlimited" advertised only after Phase 0 measurement | implemented (A03, A25) |
| M-01 | Discover | implemented (A01) |
| M-02 | Account and consent, versions recorded | implemented (A04) |
| M-03 | 18-plus gate, `verified (demo)` | implemented (A04, A27) |
| M-04 | Profile and content preferences, off by default | implemented (A05, A27) |
| M-05 | Companion detail | implemented (A02) |
| M-06 | Simulated checkout | implemented (A06) |
| M-07 | Memory controls | implemented (A10) |
| M-08 | The room: text, simulated voice, still images | implemented (A08) |
| M-09 | Data export and account deletion | implemented (A14, A26) |
| C-01…C-04, C-06 | Creator roster, rights, licence timeline, aggregate metrics | implemented |
| C-05 | Agent approvals with disclosure and human review | implemented — writes `agent_action_approved` |
| T-01…T-06 | Single file, no network, text nodes + reset, comment convention, adapter registry, deterministic simulation | implemented (A16) |
| P-01 | Four rights statuses | implemented (A15, A21) |
| P-02 | AI disclosure, never a live celebrity | implemented (A08, A18) |
| P-03 | Mature content by consent and jurisdiction; no explicit material involving a real person | implemented (A23, A27) |
| P-04 | Policies as labelled outlines, counsel writes the wording | implemented (A24) |
| P-05 | No manipulative subscription pressure | implemented (A13) |
| P-06 | Aggregate insights only; no transcript or memory on the creator route | implemented (A25) |

---

## What is explicitly not built

No live identity, payments, inference, speech, avatar, social, age-assurance, or
record-anchoring service. No store integration, card form, or external link. No
real hotline routing beyond the sample card. No 4K work, no approved demo
assets, no real likeness. The crisis screen is a fixture phrase list and will
miss real phrasing; that is why production runs a real screen on the rack.
