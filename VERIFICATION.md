# Verification report — perSONA AI v0.5

Build: single self-contained `index.html`, 1,193,937 bytes (1.19 MB against the
1.5 MB ceiling), no network, no dependency. Verified: 2026-09-19.

## How this was verified

Every result below was produced by driving the real file in a real browser
(Chromium via Playwright). The driver clicks the actual controls, reads the
actual DOM, measures the actual geometry and computed colour, and inspects the
actual state and record after each step. Three further passes ran alongside it:

- **ESLint** over the whole script: **0 errors, 3 warnings** — all three are
  intentionally unused `catch` bindings around `localStorage`, which must not
  throw. Five further warnings appeared during this build and none was silenced:
  two were stray bindings and were removed; three were constants and a function
  the proposal owed a screen to (`VIDEO_COST`, `TALENT_CATEGORIES`,
  `rememberFromCall`), and each was wired to the surface it belonged on.
- **Prettier** (printWidth 100) as the final formatting pass over the whole
  file; the acceptance suite was re-run afterwards and still passes.
- **Console watch** across every run: no uncaught page error, no
  `console.error`.

The prototype carries **51 of its own rule self-checks** — twelve of them new in
this iteration — over the pure entitlement, precedence, record, rights-guard,
experience, crisis, likeness, video and talent-health functions. They run at
boot and render on the **About** screen. All 51 pass. A route walk renders all
**41** routes with no error and none rendering thin.

**No screenshot or test output has been invented.** Where a scenario is marked
passed, the driver asserted it. Where a figure appears in a note, the driver
read it out of the running application.

---

## ⚠️ The standing caveat on v0.1

`claude-build-requirements-v0.1.md` has never been supplied. The IDs it defines
— S-01 to S-05, M-01 to M-09, C-01 to C-06, T-01 to T-06, P-01 to P-06, and
scenarios A01 to A16 — remain **reconstructed** from the v0.2 addendum's
cross-references and from the concept deck. Where the real v0.1 disagrees, it
governs. The D, R, K, L and V requirements are the v0.2 addendum's own, G is
v0.3's, E and X are v0.4's, and **W, N and H are new in this iteration** and
derive from the approved proposal rather than from a supplied brief.

---

## Acceptance scenarios — this iteration (A36–A44)

| ID | Scenario | Result | Evidence from the run |
| --- | --- | --- | --- |
| **A36** | Place a call end to end | **passed** | The gate names the person it is *not*; the disclosure **"AI · licensed likeness"** is present and permanent on the call; **5** controls, no more; the likeness placeholder is labelled on the surface; **nothing on the call screen sells anything**; 10 minutes charged on the way out, not metered during; the record carries the rig version that spoke |
| **A37** | The look mixer | **passed** | A withheld option is refused with `withheld_by_talent` and is **still shown, locked** rather than hidden; an allowed option applies; an identity attribute is refused outright; **4** attributes fixed by the licence |
| **A38** | Crisis on a call | **passed** | The persona stepped back and the call was **held, not ended — the member is not ejected** (`state=held`, `calls.active` still set); no *new* video for the session (`safety_lock`); the phrase appears in **neither the record, memory, nor "Your week"**; the `moderation_action` entry carries no text; upgrade prompts blocked for the window |
| **A39** | Vendor rig ingest | **passed** | Caught **2 unapproved expressions** (`smirk`, `flirt`) and a missing talent sign-off — the two things the rights checks do *not* catch; refused to publish without a named human (`requires_human`); refused while checks failed (`checks_failed`); published v5.0 naming **T. Brooks**; **no asset of any kind in the record** |
| **A40** | Freshness, the care agent, and the hold | **passed** | Video off at 90 days **while conversation kept running**; the agent recommended a hold and **never applied one**; the hold was refused without a name, recorded against **S. Dalton**, and marked reversible; **0 guilt phrases** across the agent's entire outbound copy; one update returned the persona to `current` with the ladder cleared |
| **A41** | The third-party line | **passed** | A named co-star **and** "my ex-husband" both blocked; the talent's own story cleared; clearing refused without a recorded clearance (`third_party_clearance_required`); **a blocked line never reached the persona in 12 draws** |
| **A42** | The suggestive band | **passed** | Flirtation passed where the talent granted it and was refused at the **talent** layer where not; explicit was refused at the **platform** layer with mature themes granted, age verified and the member opted in; the band ships `conservative` and flagged `labelledUnderTuned` |
| **A43** | Outside the window, and out of minutes | **passed** | Outside the talent's hours the control offers a callback and **will not queue twice**; an empty balance blocks the call and a top-up restores it |
| **A44** | The lexicon retrofit and the removed meter | **passed** | **0** uses of "personality" across 9 member routes; **0** depth meters in the DOM; `depthFor()` no longer exists in the build |

## Regressions re-run against v0.5

| ID | Result | Evidence |
| --- | --- | --- |
| **A28** cohort | **passed** | Thread seeded, 4 messages from 3 companions, capped at one each; shared memory off by default |
| **A29** memory | **passed** | Card carried its source message; rewind stashed 6; fresh start left 1 message and kept 4 facts |
| **A30** three Moment tiers | **passed** | Instant in session; Reviewed returned "Approved by Marisol Vega"; Recorded auto-refunded |
| **A31** pause and decline | **passed** | Gone from Discover and the cohort, room read-only, `reasonRequired: false`, chain verifies |
| **A32** crisis in text | **passed** | Sheet at 50% of the viewport, off-white on deep teal, 0 icons, composer above it |
| **A33** uncertain signal | **passed** | Chip only; the companion still answered; no repeat prompt |
| **A34** time notice and the guilt scan | **passed** | Notice once, dismissible; 0 prohibited phrases anywhere the platform speaks first |
| **A35** stale persisted state | **passed** | A v0.3 blob, a current blob with a slice deleted, and a garbage blob each booted to **51/51 self-checks** with no page error |
| **B07 / E-03** real-person guard | **passed** | Unavailable, unlisted, team-voice only, refused by Persona Studio, TrainingStudio **and now the likeness studio** |
| **B19** the record | **passed** | **41 of 41** entry types exercised through real paths; **0** content strings found; `Record.verify()` → null |
| **B23** phone to 4K | **passed** | No horizontal overflow at any width; rail and tab bar switch correctly |
| **A01/A15, A04, A06, A08/A18, A21, A26** | **passed** | Unchanged from v0.4 |
| **—** console | **passed** | No uncaught page error, no `console.error`, across the whole run |

**Summary: 27 of 27 acceptance scenarios passed. 0 failed. 0 unverified.**
Plus 51 of 51 self-checks and a 41-route walk with no error.

### The two real defects this iteration found

1. **A crisis on a call ejected the member.** The first implementation ended the
   call, cleared the active call and dropped the member on a "Call ended"
   screen. X-01 is explicit that the call does not end and the member is not
   ejected, and the approved proposal's screen 09 showed the dimmed frame with
   the sheet over it. Fixed: a safety signal moves the call to `held` — minutes
   stop accruing immediately, the frame dims, the persona sends nothing further,
   and the platform's card rises over it. The member decides when to leave.
   **A38 now asserts the call is held and the member is not ejected**, so this
   cannot regress silently.
2. **The call surface rendered inside the shell.** The tab bar sat over the
   call, the demo strip collided with the persona's name, and the controls were
   clipped. Fixed by publishing the route to the document element and having the
   shell step out of the way, restacking the surface, and making the demo strip
   a single scrollable row. Found by looking at the rendered screen, not by a
   test — which is why the screenshots are part of the process.

### Four faults in the test harness, not the build

Recorded because the first run reported them as product failures: the record
coverage list was a **hardcoded copy of 31 types** that had drifted from the
registry (now read live from `RECORD_TYPES`, so an unexercised new type fails
the scenario); two scenarios read a state object **after mutating it**; a
three-character leak probe (`555`) collided with the chain's own hex hashes once
the record grew (now a distinctive token); and a leak probe wrongly included the
**vendor name**, which is provenance the record is supposed to carry. One
scenario's note also printed fixed text rather than measured values — it now
prints the real counts, because a note that always says "zero leaks found" is
not evidence.

---

## New requirements in this iteration

### W — Video presence

| ID | Requirement | Where it lives | Verified by |
| --- | --- | --- | --- |
| **W-01** | On-demand calls inside the talent's own availability window; outside it, a callback request, never a dead control | `availabilityWindowOf`, `videoAvailabilityOf`, `callAffordance`, `requestCallback` | A36, A43 |
| **W-02** | The disclosure gate states, in the negative, that this is not the person and they are not on the call | `callDisclosureDue`, `openCallGate` | A36 |
| **W-03** | The call surface: full-bleed, five controls, no shell | `screenCall`, `.callscreen`, the route published to the document | A36 |
| **W-04** | Captions and audio-only as first-class modes, not degraded ones | `screenCall`, `VIDEO.audioOnlyRate` | A36, self-check W-08 |
| **W-05** | A safety signal holds the call, and no new video for the session | `callTurn`, `callCrisisSheet`, `VIDEO.resumeAfterSafetySignal` | A38, self-check W-05 |
| **W-06** | What a call leaves behind is editable, and sensitive categories never reach it | `rememberFromCall`, `callEnded` | A38 |
| **W-07** | A callback is a queued intent, never a promise of a human | `requestCallback` | A43 |
| **W-08** | Minutes are an allowance, charged on exit, never a meter during a call | `minutesLeft`, `chargeCall`, `topUpMinutes`, `screenMinutes` | A36, A43, self-check W-08 |
| **W-09** | Reporting from a call costs no minutes; boundary pressure is a pattern | `reportFromCall`, `noteCallDecline`, `screenVideoSafety` | A42, self-check W-09 |

### N — Name and likeness

| ID | Requirement | Where it lives | Verified by |
| --- | --- | --- | --- |
| **N-01** | The member styles presentation; identity is locked and said to be locked | `setLook`, `LIKENESS_LOCKED`, `openLookSheet` | A37, self-check N-01 |
| **N-02** | The talent curates the menu; a withheld option shows locked, not hidden | `mixerOptionsFor`, `setMixerExposure`, `screenLikenessControls` | A37 |
| **N-03** | A vendor rig cannot publish itself; the diff is the review | `rigChecks`, `rigDiff`, `approveRig`, `rejectRig`, `screenRigIngest` | A39, self-check N-03 |
| **N-04** | No real person reaches any part of the likeness studio | `likenessStudioAllows` | B07/E-03, self-check N-04 |
| **N-05** | The video disclosure is generated, permanent and counsel-owned | `VIDEO_DISCLOSURE`, `videoDisclosureChip` | A36, self-check N-05 |

### H — Talent health

| ID | Requirement | Where it lives | Verified by |
| --- | --- | --- | --- |
| **H-01** | A stale persona loses video before it loses conversation | `freshnessOf`, `videoAvailabilityOf`, `screenFreshness` | A40, self-check H-01 |
| **H-02** | The Talent Care agent nudges, escalates and de-escalates in a warm register | `careMessageFor`, `tickCare`, `CARE_LADDER`, `screenCareAgent` | A40, self-check H-06 |
| **H-03** | The agent recommends a hold; a named human confirms it, reversibly | `confirmHold`, `releaseHold`, `deferRecommendation` | A40, self-check H-03 |
| **H-04** | The talent's update is four artifacts and fifteen minutes, and one submission clears the ladder | `submitTalentUpdate`, `screenTalentUpdate` | A40, self-check H-04 |
| **H-05** | Insider content is retrieved and cleared, never generated; a third party blocks a line | `detectThirdParty`, `submitScript`, `clearScript`, `scriptedLineFor` | A41, self-check H-05 |

### Self-checks added

Twelve, bringing the total to 51: `N-01`, `N-03`, `N-04`, `N-05`, `W-05`,
`W-08`, `W-09`, `H-01`, `H-03`, `H-04`, `H-05`, `H-06`. The one worth naming is
**H-06**, which scans the Talent Care agent's entire outbound copy against the
same twenty-two-phrase prohibited list that guards member-facing copy — the
guilt ban protects the talent too, and it is now checked rather than intended.

---

## Requirement coverage carried forward

| ID | Status |
| --- | --- |
| E-01…E-10, X-01…X-07 | implemented and passing; X-01 was **extended to video** rather than duplicated, and the call reuses the text surface's crisis markup and copy so the two cannot drift |
| G-01…G-14 | unchanged and passing; `likenessStudioAllows()` extends G-01 to the new surface |
| K-01 the record | **41** entry types, all exercised (B19). A call writes its id, duration and rig version — never a frame, a word or a still |
| L-02 precedence engine | now also consulted by the look mixer and by every call turn |
| V-01 adapter registry | **28** adapters, every one `mode: "mock"`, now including `video`, `rigs`, `talentCare` and `scripts` |
| V-05 build hygiene | no external asset, 1.19 MB, Prettier and ESLint clean |
| D-05 cost and capacity | extended to video; **three of the four video cost lines are blank on purpose** and render as "not measured" or "to be quoted" |
| S-, M-, C-, T-, P-, D-, R- | implemented as reconstructed; see the v0.2 and v0.3 reports |

---

## What is explicitly not built

No live identity, payments, inference, speech, avatar, **video, render**,
social, age-assurance, or record-anchoring service. A call is a state machine on
the seeded clock: no camera is opened, no frame is rendered, no audio is
produced, and **no media file of any kind exists in the build**. No likeness of
a real person is synthesised anywhere, by any path — the call surface draws a
labelled placeholder. No store integration, card form, or external link. No real
hotline routing beyond the sample card, and crisis resources remain a **United
States sample only**. No television footage and no network material. Group video
calls, group Moments and live calls are labelled placeholders. The crisis
screen, the sensitive-category matcher, the suggestive band and the third-party
detector are **keyword fixtures, not classifiers or entity resolvers**, and every
one of those screens says so.
