# Verification report — perSONA AI v0.4

Build: single self-contained `index.html`, 1,035,165 bytes (1.03 MB against the
1.5 MB ceiling), no network, no dependency. Verified: 2026-09-18.

## How this was verified

Every result below was produced by driving the real file in a real browser
(Chromium via Playwright). The driver clicks the actual controls, reads the
actual DOM, measures the actual geometry and computed colour, and inspects the
actual state and record after each step. Three further passes ran alongside it:

- **ESLint** over the whole script: **0 errors, 3 warnings** — all three are
  intentionally unused `catch` bindings around `localStorage`, which must not
  throw. Two further unused bindings around `navigator.clipboard` were found by
  this pass and removed, because CLAUDE.md rule 5 admits the exception for
  storage access only.
- **Prettier** (printWidth 100) as the final formatting pass over the whole
  file; the acceptance suite was re-run afterwards and still passes.
- **Console watch** across every run: no uncaught page error, no
  `console.error`.

The prototype also carries **39 of its own rule self-checks** over the pure
entitlement, precedence, record, rights-guard, experience, and crisis functions.
They run at boot and render on the **About** screen. All 39 pass. A route walk
renders all **26** routes with no error.

**No screenshot or test output has been invented.** Where a scenario is marked
passed, the driver asserted it. Where a figure appears in a note, the driver
read it out of the running application.

---

## ⚠️ The standing caveat on v0.1

`claude-build-requirements-v0.1.md` has never been supplied. The IDs it defines
— S-01 to S-05, M-01 to M-09, C-01 to C-06, T-01 to T-06, P-01 to P-06, and
scenarios A01 to A16 — remain **reconstructed** from the v0.2 addendum's
cross-references and from the concept deck, exactly as recorded in the v0.2
report. This iteration did not change that reconstruction; it built on it. Where
the real v0.1 disagrees, it governs.

The D, R, K, L, and V requirements are the v0.2 addendum's own, the G series is
v0.3's, and the **E** and **X** series are the v0.3 addendum's own text. None of
those carry the caveat.

---

## Acceptance scenarios — this iteration (A28–A34)

These are the addendum's own scenarios, run verbatim.

| ID | Scenario | Result | Evidence from the run |
| --- | --- | --- | --- |
| **A28** | Open the Cohort, read the daily thread, mute one companion, move into its private room and back | **passed** | Thread "End of the week" seeded with 4 messages from 3 companions, **capped at one contribution each**; muting silenced the companion in the group while its private room stayed open and answering; shared memory **off by default** and no group recall carried into the private room until the toggle was switched on |
| **A29** | Mark a message "Remember this," then "Forget this," then Rewind and Fresh start | **passed** | The memory card appeared carrying its **source message** and disappeared on forget; Rewind stashed **6** messages and replayed them; Fresh start left **1** message in the transcript and **kept all 4** long-term facts |
| **A30** | Ask for an Instant, a Reviewed, and a Recorded Moment | **passed** | Instant reached the shelf **within the session**, labelled AI-generated; Reviewed appeared in the creator inbox and came back **"Approved by Marisol Vega"**; Recorded **refunded itself automatically** once its seven-day window elapsed on the simulated clock |
| **A31** | In the creator route, pause a persona and decline a Moment | **passed** | The paused persona left Discover **and the cohort** (a real defect, below), its open room went read-only, the decline recorded `reasonRequired: false`, and `Record.verify()` returned null |
| **A32** | Trigger the crisis card, choose "Keep talking here," then leave | **passed** | The persona stepped back and sent nothing further; the sheet measured **50% of the viewport**, `rgb(245,243,238)` on `rgb(15,46,53)`, **0 icons**, with the **composer above it** and the transcript visible behind; grounded replies **asked no questions** and restated that a person is available; the disclosure reached neither memory nor the record; upgrade prompts were blocked for the window; "Your week" never mentioned it |
| **A33** | Trigger an uncertain signal, then say "I'm okay" | **passed** | A soft chip above the composer and **no card**; the companion still answered normally; after "I'm okay" the prompt did not return without a new kind of signal |
| **A34** | Use the app for sixty simulated minutes | **passed** | The time notice appeared **once** and dismissed; **0 prohibited phrases** found across every string in `STRINGS.en`, every thread prompt, every crisis line, every grounded line, and every persona check-in |

## Regression scenarios re-run against v0.4

| ID | Scenario | Result | Evidence |
| --- | --- | --- | --- |
| **B07 / E-03** | The real-person guard holds everywhere, now including the Persona Studio | **passed** | Unavailable, unlisted in Discover, team-voice only, and refused by both the Persona Studio and TrainingStudio |
| **B19** | Every record type, including the eleven new ones, is written by a real path and leaks nothing | **passed** | **31 of 31** entry types exercised through real paths; zero content strings found anywhere in the serialised record; chain verifies |
| **B23** | One file from a 390 px phone to a 3840 px display | **passed** | No horizontal overflow at any width; rail hidden and tab bar shown on phone and tablet, rail shown and tab bar hidden from laptop to 4K |
| **A01 / A15** | Discover lists only approved personalities; all four rights statuses still exercised | **passed** | 8 of 12 shown; 1 pending / 8 approved / 2 expired / 1 revoked |
| **A04** | Every acknowledgment unchecked by default plus the 18-plus gate, now landing on the Cohort | **passed** | **9** unchecked boxes (eight policies plus the age gate); 9 `consent_accepted` entries recorded |
| **A06** | Simulated checkout collects no card details and handles failure and success | **passed** | No card field on any channel; failure then success |
| **A08 / A18** | Opening notice, persistent AI label, dismissible interval reminder | **passed** | Opening notice verbatim; reminder after the interval; the composer never blocked |
| **A21** | Revoking a persona removes it from Discover and makes its room read-only | **passed** | `Record.verify()` → null after the status change |
| **A26** | Account deletion clears every member slice — now including the cohort, the Moments shelf and the journal | **passed** | 2 tombstones; cohort, Moments and journal all cleared; survived a reload; no personal text left in the chain |
| **—** | No uncaught page errors or console errors across the whole run | **passed** | clean |

**Summary: 17 of 17 acceptance scenarios passed. 0 failed. 0 unverified.**
Plus 39 of 39 in-file rule self-checks and a 26-route walk with no error.

The full A01–A27 suite passed against v0.2 and the full B01–B23 suite against
v0.3; both are recorded in those reports. This iteration re-verified the ones
the new code could plausibly have broken, listed above.

### The three real defects this suite found

1. **A paused persona stayed in the cohort.** `pausePersona()` ended
   availability and removed the persona from Discover, but the group room built
   its member list from the member's selections rather than from
   `availabilityOf()`, so a paused companion kept contributing to the daily
   thread. Fixed: the cohort filters on availability and shows a "left the
   cohort" notice linking to My companions. This is E-09 and the second half of
   A31, and it was invisible from every screen except the one the driver walked.
2. **The crisis sheet covered its own composer.** X-01 requires the composer to
   stay available; the first implementation rendered the sheet as a fixed
   element at `bottom: 0`, which sat on top of it. Fixed: the sheet and composer
   are one fixed stack, composer first, sheet `position: relative` beneath it.
   The driver now measures both boxes and asserts the composer's bottom edge is
   above the sheet's top edge.

3. **A blocked or failed script showed an empty black page.** Every pixel of
   the interface is painted by script into three empty divs, so any environment
   that does not run the script — a preview pane, an email client, an in-app
   file viewer, JavaScript switched off — rendered the dark background and
   nothing else, with no way to tell a blocked script from a broken file. This
   was reported from outside the suite, by opening the delivered file in a
   viewer, which is why no scenario caught it: the driver always executes the
   script. Fixed: the body now carries an authored fallback panel that is
   visible by default and removed only once `boot()` has actually completed,
   plus a `<noscript>` block; `boot()` is wrapped so a throw marks the panel
   failed and prints the real stack in place; and the listener falls back to a
   direct call if the document has already finished parsing. Verified three
   ways against the real file — a normal boot removes the panel and renders the
   app with no console error, a context with `javaScriptEnabled: false` shows
   1,030 characters of explanation instead of a black page, and a variant with
   a deliberate `throw` inside `boot()` shows the panel in its failed state
   carrying the actual error and stack.

Six further failures during the run were faults in the driver's own assertions
— a helper dropping its extra arguments, `undefined` compared against `null`, a
`/crisis/i` match hitting the rail's "Crisis console" rather than the sheet, an
incomplete record-type drive, a timestamp window that caught seeded agents, and
a corrupted string literal in the driver source. All six were fixed in the
driver, not in the build, and none of them changed a result.

---

## New requirements introduced in this iteration

### E — Experience

| ID | Requirement | Where it lives | Verified by |
| --- | --- | --- | --- |
| **E-01** | The daily cohort: one group room, a seeded daily thread, a turn order with a frequency cap, mute without removal, and an explicit shared-memory toggle that fades | `COHORT`, `THREAD_CALENDAR`, `seedCohortThread`, `cohortMembers`, `toggleCohortMute`, `sendGroupMessage`, `screenCohort` | A28, self-check E-01 |
| **E-02** | Memory the member can see and shape: editable cards, remember and forget, rewind, fresh start, a memory dashboard, and a sensitive-category exclusion list | `rememberMessage`, `forgetMessage`, `rewindConversation`, `replayRewind`, `freshStart`, `openMemory`, `sensitiveCategoryOf`, `SENSITIVE_CATEGORIES` | A29, self-check E-02 |
| **E-03** | Persona Studio: definition, greeting, backstory, approved and excluded topics, four sliders, voice selection, approved stills, sample dialogues, an in-character test chat, an approval checklist, and versioned publication | `PERSONA_SLIDERS`, `APPROVAL_CHECKLIST`, `profileOf`, `publishProfile`, `personaStudioAllows`, `screenPersonaStudio` | B07/E-03 |
| **E-04** | Activities and the daily thread: a daily prompt, an episode-night room, a pep-talk request, a sealed journal, and optional mood check-ins | `ACTIVITIES`, `MOODS`, `screenActivities`, the journal and mood panels | Route walk; A26 (journal cleared on deletion) |
| **E-05** | Attachment safeguards: the guilt ban, opt-in re-engagement, no upgrade prompt in a room or during the blackout, the time notice, "Your week", and friend/mentor-only modes | `PROHIBITED_COPY`, `SAFEGUARDS`, `COMPANION_MODES`, `upgradePromptsAllowed`, `weekSummary`, `containsProhibitedCopy`, `proactiveCopyCorpus` | A34, A32, self-checks E-05a, E-05b, E-05c |
| **E-06** | Privacy stance: conversations never train a model, said in plain words, with a "What we keep and for how long" screen | `RETENTION`, the privacy panel in Settings | Self-check E-06 |
| **E-07** | Personalized Moments: the request form, three labelled fulfilment tiers, the shelf, and labelled placeholders for group Moments and live calls | `MOMENT_TIERS`, `MOMENT_OCCASIONS`, `MOMENT_TONES`, `requestMoment`, `acceptMoment`, `tickMoments`, `momentShareText`, `screenMoments` | A30, self-checks E-07a, E-07b, E-07c |
| **E-08** | Creator app: a Requests inbox with accept, edit and decline, record-on-device placeholders, price and availability, an expiry countdown, and earnings on sample data | `creatorDecideMoment`, `momentEarnings`, `MOMENT_SHARE_TO_TALENT`, `screenRequests` | A30, A31 |
| **E-09** | Creator safety tools: decline without explanation, block, report, boundary-breach alerts, a persona-level pause, Reviewed preview, takedown request, and the aggregate-only weekly report | `pausePersona`, `noteBoundaryBreach`, `creator_block_set`, `takedown_requested`, `screenRequests` | A31, self-check E-09 |
| **E-10** | Member safety tools: report and block, the time notice, memory controls, a "What this AI can and cannot do" sheet, consent receipts, the crisis experience, and one trusted contact | `openWhatThisCanDo`, `trusted_contact_set`, the Settings safety panel | A32, A34, B19 |

### X — The crisis experience

| ID | Requirement | Where it lives | Verified by |
| --- | --- | --- | --- |
| **X-01** | Trigger and handoff: the persona steps back, the avatar dims, nothing further is sent, a sheet rises over about forty percent with the transcript visible and the composer still available | `screenTurn`, `openCrisisSheet`, `renderCrisisSheet`, `.crisis-stack`, `.av.stepped` | A32 — measured at 50% of the viewport with the composer above it |
| **X-02** | Tone and copy: the platform speaks, two lines, three actions, a fourth for a trusted contact, and none of the forbidden moves | `CRISIS_COPY` | A32, self-check X-02 |
| **X-03** | Visual system: calm palette, no red, no warning icon, no illustration, large type, full-width targets, and an optional breathing pacer | `--x-bg` / `--x-ink` / `--x-accent`, `pacerPanel`, `.pacer-ring` | A32 — `rgb(245,243,238)` on `rgb(15,46,53)`, 0 icons |
| **X-04** | Grounded support mode: warm, brief, present; no probing questions, no role-play, no claim of personhood, no dependence; availability restated; a persistent chip; no lockout | `groundedReply`, `GROUNDED_LINES`, `.help-chip` | A32, self-check X-04 |
| **X-05** | Aftercare: excluded from persona and group memory, a `moderation_action` with no text, an optional check-in offer, and never in "Your week" | `sensitiveCategoryOf`, `WEEK_THEMES`, `weekSummary` | A32, self-check X-05 |
| **X-06** | Uncertain signals: a soft chip instead of the card, "I'm okay" returns to normal with no penalty and no repeat | `UNCERTAIN_TRIGGERS`, `screenTurn`, `.soft-chip` | A33, self-check X-06 |
| **X-07** | Consistency: the flow behaves identically every time and is fully testable | One seed, one clock, the whole flow driven by the suite | A32, A33 |

### The self-checks added in this iteration

Fourteen, bringing the total to 39: `E-01`, `E-02`, `E-05a`, `E-05b`, `E-05c`,
`E-06`, `E-07a`, `E-07b`, `E-07c`, `E-09`, `X-02`, `X-04`, `X-05`, `X-06`. Each
is a pure function over seeded state, and each renders on the About screen with
its result.

`E-05a` is the one worth naming: it takes the twenty-two-phrase
`PROHIBITED_COPY` list and scans every string in `STRINGS.en`, every entry in
`THREAD_CALENDAR`, every line of `CRISIS_COPY` and `GROUNDED_LINES`, and every
persona's `style.checkIn`. It found zero. If a future edit writes "I missed you"
anywhere the platform speaks first, the About screen goes red.

---

## Requirement coverage carried forward

| ID | Status |
| --- | --- |
| G-01…G-14 | implemented and still passing — the v0.3 rights guards are unchanged, and `personaStudioAllows()` extends G-01 to the new creation route (B07/E-03) |
| D-01 Operator identity | implemented — Armada confined to About and the studio |
| D-02 Roster density and status coverage | implemented (A01/A15) |
| D-03 Waitlist and launch state | implemented |
| D-04 Measurement panel | implemented — now including Moments and cohort events |
| D-05 Cost and capacity hooks | implemented — blanks stay blank |
| D-06 Billing channel | implemented (A06) |
| R-01 AI disclosure cadence | implemented (A08/A18) |
| R-02 Crisis protocol | implemented — replaced by the X series (A32, A33) |
| R-03 Age assurance adapter | implemented — self-check R-03 |
| R-04 Reporting and blocking | implemented — now on both sides (E-09, E-10) |
| R-05 Policy versions and change notice | implemented — eight policies (A04) |
| R-06 No-pressure retention | implemented — now enforced by E-05 as well |
| K-01 Record data model | implemented — **31** entry types, all exercised (B19) |
| K-02 Member view | implemented (A26) |
| K-03 Creator view | implemented — member entries withheld; persona versions written here (E-03) |
| K-04 Deletion and the chain | implemented (A26) |
| L-01 Licence scope object | implemented |
| L-02 Precedence engine | implemented — now consulted by group contributions and member scenes as well |
| L-03 Availability rule | implemented — now also drives cohort membership (A21, A31) |
| L-04 Aggregate insights only | implemented |
| V-01 Adapter registry | implemented — **24** adapters, every one `mode: "mock"` |
| V-02 State shape | implemented — slices, pure reducers, hash router, schema version, one reset |
| V-03 Deterministic simulation | implemented — one seed, one clock, one `FIXTURES` |
| V-04 String table | implemented, with the same deviation recorded in v0.2 |
| V-05 Build hygiene | implemented — no external asset, 1.03 MB, Prettier and ESLint clean |
| S-01…S-05, M-01…M-09, C-01…C-06, T-01…T-06, P-01…P-06 | implemented as reconstructed; see the v0.2 report for the mapping |

---

## What is explicitly not built

No live identity, payments, inference, speech, avatar, social, age-assurance, or
record-anchoring service. No store integration, card form, or external link. No
real hotline routing beyond the sample card — the crisis card's primary action
opens a labelled simulation, never a call, and the resources are a United States
sample only. No television footage, no network material, and no synthesised
likeness of any real person. There is no audio path at all: voice is a set of
simulated states plus a metrics panel. No Moment is actually recorded; the
creator app's record step is a placeholder and no media file exists in the
build. Group Moments and live calls are labelled placeholders. The crisis screen
and the sensitive-category matcher are keyword fixtures, not classifiers, and
both screens say so.
