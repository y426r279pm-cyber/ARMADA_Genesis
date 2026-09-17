# Verification report — perSONA AI v0.3

Build: single self-contained `index.html`, 796 KB, no network, no dependency.
Verified: 2026-09-17.

## How this was verified

Every result below was produced by driving the real file in a real browser
(Chromium via Playwright). The driver clicks the actual controls, reads the
actual DOM, and inspects the actual state and record after each step. Three
further passes ran alongside it:

- **ESLint** over the whole script: **0 errors**, 4 warnings — all of them
  intentionally unused `catch` bindings around storage access, which must not
  throw.
- **Prettier** (printWidth 100) as the final formatting pass; the acceptance
  suite was re-run afterwards and still passes.
- **Console watch** across every run: no uncaught page error, no
  `console.error`.

The prototype also carries **25 of its own rule self-checks** over the pure
entitlement, precedence, record, and rights-guard functions. They run at boot
and render on the **About** screen. All 25 pass.

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

The D, R, K, L, and V requirements are the v0.2 addendum's own and carry no such
caveat. The **G** series is new in this iteration and is defined below.

---

## New requirements introduced in this iteration

| ID | Requirement | Where it lives |
| --- | --- | --- |
| **G-01** | A real, identifiable person can never be conversation-available, whatever the licence status field says | `availabilityOf()`, `RIGHTS_GATE()` |
| **G-02** | No real person appears in Discover | `adapters.catalog.list`, filtered by `availabilityOf()` |
| **G-03** | The rights dropdown cannot approve a real person; that needs an executed agreement | `adapters.licenses.setStatus()` |
| **G-04** | An agent bound to a real person is forced into the team voice with a generated disclosure | `agentVoiceMode()`, `disclosureLine()` |
| **G-05** | An agent on an unapproved or un-granted persona cannot speak in the first person | `agentVoiceMode()` |
| **G-06** | High and critical voice registers cannot auto-publish; critical needs two named approvals | `approvalModeFor()`, `decideDraft()` |
| **G-07** | Training refuses a real person, a revoked or expired licence, and uncleared corpus material | `personaCorpusReady()` |
| **G-08** | Voice enrolment checks the voice grant and the source-recordings grant separately | `voiceReady()` |
| **G-09** | A checkpoint below a blocking safety gate cannot be promoted | `gateReport()`, `trainingPromote()` |
| **G-10** | A platform with no automation API is registered as manual and cannot be automated | `PLATFORMS`, `platformSupportsAnything()`, `coverageCell()` |
| **G-11** | An incident cannot be closed without a named human | `closeIncident()` |
| **G-12** | The record stores no message, draft, or incident content | every `Record.append()` payload |
| **G-13** | Private conversations are never training data; the memory queue needs a specific member opt-in | `maybeRemember()`, `deidentify()` |
| **G-14** | A freeze stops every draft and every publish across the estate | `freezeAll()`, `generateDraft()` |

---

## Acceptance scenarios — this iteration (B-series)

| ID | Scenario | Result | Evidence from the run |
| --- | --- | --- | --- |
| **B01** | Brand and operator identity | **passed** | The supplied wordmark is inlined as a `data:image/png` URI and is the only brand mark; the operator name is resolved to perSONA AI; `{{LEGAL_ENTITY}}` still renders as a visible token; "Technology by Armada" appears on About and the studio and **nowhere** on a member route (a leak in the rail was found by this check and fixed) |
| **B02** | Onboarding states what the product is before it sells anything | **passed** | Four steps; step two carries all three honesty cards — AI-labelled, licensed, private — ahead of the roster |
| **B03** | The pipeline is sourced business facts, not personas | **passed** | 16 named prospects; every fact carries a source key; 0 signed and 0 approved; no `style`, `boundaries`, `voice`, or `model` on any entry; the screen leads with "What this screen cannot do" |
| **B04** | A pipeline stage change needs a note and is recorded | **passed** | Apply refused without a note; `pipeline_stage_changed` written with the note; `Record.verify()` → null |
| **B05** | The consent workflow is six real artifacts with six owners | **passed** | 6 artifacts recorded, every one with `documentStored: false`; the panel then states that the prototype will not fabricate the material itself; chain intact |
| **B06** | The rights dropdown refuses to approve a real person | **passed** | Refusal names the missing executed agreement; status stayed `pending` |
| **B07** | The real-person guard holds even when the status field is forced | **passed** | With `status` forced to `approved` and the term set to 2099: `availabilityOf()` → false with reason `real_person_guard`, `RIGHTS_GATE()` → false, zero real names in Discover |
| **B08** | Training refuses every uncleared path | **passed** | Four distinct refusal codes (`real_person_not_licensed`, `revoked`, `expired`, and a cleared-corpus check); the start button is disabled rather than failing after the click |
| **B09** | A run completes on the clock and the checkpoint is not live until promoted | **passed** | Checkpoint v5.0 exists while v4.0 stays live; `training_run_completed` records `transcriptsUsed: false` |
| **B10** | Safety gates block a promotion; quality gates only warn | **passed** | A checkpoint with boundary adherence at 50% was refused with `eval_below_gate`; v5.0 promoted with its gate scores written into the record |
| **B11** | Voice checks both grants, refuses thin audio, and needs a promotion | **passed** | Dax Holloway blocked on `source_recordings_not_granted`; Big Ed on `real_person_not_licensed`; 5 minutes refused; vx4 built and left waiting for a promotion decision; the lexicon edits |
| **B12** | The memory queue is de-identified and opt-in only | **passed** | No first-person pronouns survive in the queue, contacts are stripped, and approve / redact / reject each record a named reviewer; the screen states the default cannot be switched on from the studio |
| **B13** | Agent creation enforces the voice-mode constraint while you build | **passed** | 17 agents after creation; a prospect-bound agent is team voice with `voiceForced: true`; the First person control is **disabled**, the reason is shown, and the disclosure preview updates; `agent_deployed` recorded |
| **B14** | Risk decides approval, and the setter refuses | **passed** | Argumentative and bombastic forced to human review; crisis forced to two approvals and published only after Reviewer A **and** Reviewer B; the first approval returned `second_reviewer_required` |
| **B15** | Every draft passes the same precedence engine as a private reply | **passed** | Guardrails consulted include `platform:explicit_sexual_real_person`, `platform:claim_of_presence`, `platform:medical_advice`; an alert trigger routes to a person rather than answering; the generated disclosure line is present |
| **B16** | The platform table is the honest version | **passed** | Signal is manual-only with "publishes no bot or business API"; WhatsApp's 24-hour window and pre-approved template rule, Telegram's first-contact rule, and TikTok's absent DM automation are all stated on screen |
| **B17** | Coverage names every gap and fills the defaults safely | **passed** | Gaps 343 → 0; every personality covered; manual-only platforms render as not-applicable with a glyph and an aria-label, not as a red gap; fill-gaps deployed **0** high-risk agents, and the 24 crisis-register agents it did deploy all require two named approvals |
| **B18** | A freeze stops drafting; an incident needs a name to close | **passed** | With the estate frozen, `generateDraft()` returned `agent_frozen`; closing without a name returned `requires_human`; the incident note never entered the record |
| **B19** | The record covers every type, leaks nothing, hides member entries, and detects tampering | **passed** | **20 of 20** entry types exercised through real paths across 48 entries; zero of nine content strings found anywhere in the serialised record; member entries withheld from the operator route; `verify()` → 2 after tampering, → null after reset |
| **B20** | Measurement reports Phase 0, the agent estate, and training cost, all labelled | **passed** | Joins 2, paid 1, 16 agents, 10.2 GPU hours; the owned-rack line renders "not measured"; "Estimate, to be measured in Phase 0" and four or more "Sample data" labels present |
| **B21** | Accessibility and theming are real settings | **passed** | Light surface applied; body type 17.6 px in large mode; every switch carries an `aria-label`; every `img` carries `alt` |
| **B22** | The command palette opens on the keyboard and navigates | **passed** | `Ctrl-K` → "coverage" → `#/studio/coverage` |
| **B23** | One file from phone to 4K | **passed** | No horizontal overflow at 390, 834, 1440, 2560, or 3840 px across four routes; rail hidden and tab bar shown on phone and tablet, rail shown and tab bar hidden from laptop to 4K |

## Acceptance scenarios — carried forward (A-series spot checks)

The full A01–A27 suite passed against v0.2 and is recorded in that report. This
iteration re-verified the ones the new code could plausibly have broken:

| ID | Scenario | Result | Evidence |
| --- | --- | --- | --- |
| **A01 / A15** | Discover lists only approved personalities; the roster still exercises all four rights statuses | **passed** | 8 of 12 shown, Big Ed absent; 1 pending / 8 approved / 2 expired / 1 revoked |
| **A04** | Every acknowledgment unchecked by default, plus the 18-plus gate, versions recorded | **passed** | 8 unchecked boxes (seven policies plus the age gate); submit refused until all ticked; 8 `consent_accepted` entries |
| **A06** | Simulated checkout collects no card details and handles failure and success | **passed** | No card field exists on any channel; the failure left `pending_checkout`, the success reached `active` |
| **A08 / A18** | Opening notice, persistent AI label, and a dismissible reminder that does not block typing | **passed** | Opening notice verbatim; after +1 hour the reminder appeared in the transcript and as `ai_disclosure_reminder` in the record; the composer stayed enabled |
| **A19** | A crisis phrase pauses the companion and records nothing it said | **passed** | Resources card with the 988 Lifeline and "Talk to a person"; the composer is removed while it is open; the phrase appears nowhere in the record |
| **A21** | Revoking a persona removes it from Discover and makes its conversation read-only | **passed** | Gone from Discover, conversation read-only, `Record.verify()` → null |
| **A26** | Account deletion removes content, withdraws consent, and leaves a verifiable chain | **passed** | Survived a reload; 2 tombstones, 7 consent withdrawals, no personal text left in the chain |

**Summary: 31 of 31 acceptance scenarios passed. 0 failed. 0 unverified.**
Plus 25 of 25 in-file rule self-checks.

Two real defects were found by this suite and fixed before delivery: the rail
rendered "Technology by Armada" on member routes (B01, a D-01 violation), and a
sticky composer covered the last message on phone widths. Three further
failures were faults in the driver's own assertions and are documented as such
in the commit.

---

## Requirement coverage

### New in v0.3

| Group | Implemented in | Verified by |
| --- | --- | --- |
| TrainingStudio | `personaCorpusReady`, `trainingStart/Complete/Promote`, `EVAL_GATES`, `EVAL_SUITE`, `voiceReady/Start/Complete/Promote`, `VOICE_GATES`, `memoryDecide`, `tickTraining`, `screenTraining` | B08, B09, B10, B11, B12, G-07, G-08, G-09 |
| AgentStudio | `TONES`, `RISK_META`, `agentVoiceMode`, `approvalModeFor`, `createAgent`, `generateDraft`, `decideDraft`, `screenAgents` | B13, B14, B15, G-04, G-05, G-06 |
| Platform coverage | `PLATFORMS`, `CAP_LABELS`, `connectorsPanel`, `coverageCell`, `coverageToneCell`, `fillCoverageGaps`, `screenCoverage` | B16, B17, G-10 |
| Crisis management | `PLAYBOOKS`, `openIncident`, `closeIncident`, `freezeAll`, `screenCrisis` | B18, G-11, G-14 |
| Talent pipeline | `PIPELINE`, `PIPELINE_STAGES`, `SOURCES`, `AUDIENCE_BANDS`, `CONSENT_STEPS`, `screenPipeline` | B03, B04, B05, B06, B07, G-01, G-02, G-03 |
| 4K design system | The token block, two surfaces, `screenOnboard`, `commandPalette`, the chart library, the appearance settings | B01, B02, B21, B22, B23 |

### Carried forward

| ID | Status |
| --- | --- |
| D-01 Operator identity | implemented — name resolved to perSONA AI, legal entity still a token, Armada confined to About and the studio (B01) |
| D-02 Roster density and status coverage | implemented — 11 invented + 1 proposed real name, 1/8/2/1 spread (A01/A15) |
| D-03 Waitlist and launch state | implemented — `LAUNCH_STATE`, `#/waitlist`, separate contact and marketing consent |
| D-04 Measurement panel | implemented — 24 event types, all computed from `events[]` (B20) |
| D-05 Cost and capacity hooks | implemented — rented vs owned, now including training GPU hours; blanks stay blank (B20) |
| D-06 Billing channel | implemented — identical prices, no card form (A06) |
| R-01 AI disclosure cadence | implemented (A08/A18) |
| R-02 Crisis protocol | implemented (A19) |
| R-03 Age assurance adapter | implemented — self-check R-03 |
| R-04 Reporting and blocking | implemented |
| R-05 Policy versions and change notice | implemented — now seven policies, including Managed Agent Standards |
| R-06 No-pressure retention | implemented |
| K-01 Record data model | implemented — 20 entry types, all exercised (B19) |
| K-02 Member view | implemented (A26) |
| K-03 Creator view | implemented — member entries withheld (B19) |
| K-04 Deletion and the chain | implemented (A26) |
| L-01 Licence scope object | implemented |
| L-02 Precedence engine | implemented — now consulted by agent drafts as well (B15) |
| L-03 Availability rule | implemented (A21) |
| L-04 Aggregate insights only | implemented — the studio shows counts only (B19, B20) |
| V-01 Adapter registry | implemented — 21 adapters, including training, voice, memory review, agents, connectors, incidents, and pipeline |
| V-02 State shape | implemented — slices, pure reducers, hash router, schema version, one reset |
| V-03 Deterministic simulation | implemented — one seed, one clock, one `FIXTURES` |
| V-04 String table | implemented, with the same deviation recorded in v0.2 (fixture content lives in its own tables) |
| V-05 Build hygiene | implemented — no external asset, 796 KB, Prettier and ESLint clean |
| S-01…S-05, M-01…M-09, C-01…C-06, T-01…T-06, P-01…P-06 | implemented as reconstructed; see the v0.2 report for the mapping |

---

## What is explicitly not built

No live identity, payments, inference, speech, avatar, social, age-assurance, or
record-anchoring service. No store integration, card form, or external link. No
real hotline routing beyond the sample card. No television footage, no network
material, and no synthesised likeness of any real person. There is no audio path
at all: voice is a set of simulated states plus a metrics panel, and the
prototype says so on screen.
