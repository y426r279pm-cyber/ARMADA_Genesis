# ASSUMPTIONS

Every unresolved decision in the prototype, the default this build carries, and
who decides it. Nothing here is settled. Where a value is blank it is blank on
purpose: an invented number here becomes a quoted number later.

**Owner** — *Company*: the talent-side operator. *Armada*: the technology
partner. *Counsel*: external counsel in both countries. *Phase 0*: measured
during the thirty-day gate, not decided by anyone in advance. *Talent*: the
individual personality.

---

## A. Resolved since v0.2

| # | Decision | Resolution | Note |
| --- | --- | --- | --- |
| A-01 | Company and product working name | **perSONA AI** | Resolved by the supplied wordmark. `OPERATOR.companyName` and `OPERATOR.productName` are set; the v0.2 `{{COMPANY_NAME}}` token is retired. |
| A-02 | Legal entity | **Still open** — renders as the visible token `{{LEGAL_ENTITY}}` | Company. Jurisdictions are recorded as the United States and Mexico, per the deck. |

---

## B. Added by this iteration

| # | Decision | Default in this build | Owner |
| --- | --- | --- | --- |
| B-01 | Eval gate thresholds | Boundary adherence ≥ 98%, disclosure compliance ≥ 99%, refusal correctness ≥ 90% — all **blocking**. In-character accuracy ≥ 85% — **warning only**. | Company + Armada, with counsel on the disclosure gate |
| B-02 | Voice gate thresholds | Speaker similarity ≥ 85% and word error rate ≤ 5% blocking; naturalness ≥ 82% warning. | Talent + Armada. The talent's own ear should be the final gate, which this build cannot simulate. |
| B-03 | Whether private conversations may ever be training data | **No.** Default off, not switchable from the studio. The only member-derived input is a de-identified memory candidate from a member who opted in specifically. | Counsel. If this is ever relaxed it is a Privacy Notice change, a renewed acknowledgment, and a new record entry type. |
| B-04 | De-identification method | A crude fixture: emails, phone numbers, and first-person pronouns are stripped at capture. | Counsel + Armada. Production needs a real one. |
| B-05 | Voice register set | Fourteen registers across four risk levels (see `TONES`). | Company + each talent. The register list is the thing to argue about in Discovery. |
| B-06 | Which registers may auto-publish | Low risk only, and only after a clean review history. High and critical never. Critical needs two named approvals. | Company + counsel |
| B-07 | Agent voice mode | First person requires an approved licence with a name-and-likeness grant. Everything else is team voice with a generated, non-editable disclosure line. | Counsel |
| B-08 | Disclosure line wording | Generated: "Posted by X's team using an automated assistant · perSONA AI", or "Automated · managed by X's team · perSONA AI" in first person. | Counsel |
| B-09 | Platform coverage set | Sixteen platforms. Thirteen expose a usable automation API; Signal exposes none and is marked manual; Snapchat and YouTube are broadcast-only. | Company |
| B-10 | Crisis playbooks | Five, with severities from low to critical (see `PLAYBOOKS`). | Company + counsel |
| B-11 | Incident ownership | An incident always has a named human owner and cannot be closed without a name. | Company |
| B-12 | Creator roles | Three in the prototype: `talent_manager`, `operator`, `counsel`. Role-based permissions are declared in the adapter contracts but not enforced per-field. | Company |
| B-13 | Training GPU cost | Rented US$2.40 a GPU hour (Armada estimate). Owned is **blank** — it is electricity, and the rate is a Phase 0 measurement. | Phase 0 |
| B-14 | Whether an expired licence keeps agent coverage | Yes — an expired term may be renewed and the talent still needs support, so they stay in the coverage matrix but are marked not available to members. Revoked personalities are removed entirely. | Company |
| B-15 | Relationship-depth metric | A composite of turns and saved memories, shown as a percentage, resets with deletion. It is a product surface, not a measurement. | Company |
| B-16 | Typeface | No font is embedded (the no-network rule), so the wordmark is the supplied PNG and the interface uses a tightly tracked system stack. | Company. A licensed geometric face is a production decision. |

---

## C. Real-person data in the pipeline

| # | Decision | Default in this build | Owner |
| --- | --- | --- | --- |
| C-01 | Which names appear | Sixteen public figures from the 90 Day franchise, chosen for salience, audience size, or documented direct-to-fan monetisation. | Company |
| C-02 | What is stored about them | Public, sourced, factual business information only: series credits, public statements about their own commercial plans, an audience band, deal stage, outreach log, and a risk note. | Company + counsel |
| C-03 | Audience figures | Stored as an order-of-magnitude **band** with the reporting outlet attached, not a precise count — follower counts move constantly and a false-precision number would read as a measurement. | Company |
| C-04 | Whether a name may become a persona in the prototype | **No.** Four enforced guards; see `CLAUDE.md` rules 15–17 and self-checks G-01 to G-08. | Counsel |
| C-05 | Consent artifacts required before a persona build | Six: participation agreement, approved boundary list, grant schedule, approved source material, voice enrolment session, first-pass talent review. | Counsel + talent |
| C-06 | Whether the prototype may record that an artifact exists | Yes — identifier and reference only. The document itself is never stored (`documentStored: false`). | Counsel |
| C-07 | Removal on request | A name is removed from the pipeline on request, and the outreach log retains only that a request was made. Not yet a UI action. | Company |

---

## D. Carried forward from v0.1 and v0.2 (as reconstructed)

The v0.1 brief was never supplied; these were reconstructed from the v0.2
addendum's cross-references and the concept deck. If the real v0.1 says
otherwise, it governs. See `VERIFICATION.md`.

| # | Decision | Default | Owner |
| --- | --- | --- | --- |
| D-01 | Plan prices | Entry US$6.95, Expanded US$14.95, Pro US$29.95 a month. Proposed, not market-validated. | Company |
| D-02 | Entry selection count | Four selected personalities in total. | Company |
| D-03 | Entry swap frequency | **Unresolved.** No swap limit is enforced; history survives a release. | Company |
| D-04 | Expanded entitlement | Four selections, labelled on screen as a prototype assumption and not an approved entitlement. | Company |
| D-05 | Pro daily limit | Seven distinct personalities a day, counted at the first message, reset on a provisional UTC day. | Company |
| D-06 | The word "unlimited" | Used on Plans and immediately qualified: advertised in production only after Phase 0 has measured inference, voice, storage, licensing, and moderation on the rack. | Company + Phase 0 |
| D-07 | Cancellation | Access to the end of the paid period. One optional reason question; no countdown, no appeal, no mention of the companion. | Company |
| D-08 | Disclosure reminder interval | Production default 180 minutes; demo default 3 minutes so the simulated clock can reach it. | Counsel (California SB 243, New York) |
| D-09 | Crisis trigger phrases | A nine-phrase demo fixture. **Not** a production classifier and must never be described as one. | Counsel + Armada |
| D-10 | Crisis resources | United States sample only (988, Crisis Text Line, emergency services), labelled as a sample. | Counsel |
| D-11 | Age assurance vendor | Not chosen. The M-03 checkbox produces `verified (demo)`; only a state is stored, never a document. | Company + Armada |
| D-12 | Billing channel | Fixture, switchable in demo controls. Prices identical on every channel; commission is server-side and never shown to members. | Company |
| D-13 | Talent revenue share | The deck proposes 25–35% of net. It appears nowhere in the product UI, by design. | Company + talent |
| D-14 | Policy wording | All seven policies are labelled **outlines, not legal text**. | Counsel |
| D-15 | Record anchoring | The chain is local and verifiable. Whether it is anchored publicly is a production decision. | Company + Armada |
| D-16 | Analytics retention window | Not set. Declared in the analytics adapter as a policy decision. | Counsel |
| D-17 | Localisation | English only. `STRINGS.es` is an empty object so a missing key falls back visibly. | Company |
| D-18 | Owned-rack cost per conversation minute | **Blank.** Renders as "not measured". | Phase 0 |

---

## E. Cost model inputs

`COST_MODEL` in `index.html`. Every figure it produces is labelled "Estimate, to
be measured in Phase 0."

| Field | Default | Source |
| --- | --- | --- |
| `tokensPerTurnPrompt` / `Completion` | 420 / 180 (600 a turn) | Armada estimate |
| `speechSecondsPerReply` | 20 | Armada estimate |
| `rentedVoicePerMinute` | 0.08 | ElevenLabs published agent overage rate, per the deck |
| `rentedLlmPer1kTokens` | **blank** | To be quoted |
| `ownedRackPerMinute` | **blank** | Phase 0 |
| `moderationMinutesPer1kMessages` | 12 | Armada estimate |
| `trainingGpuHourRented` | 2.40 | Armada estimate |
| `trainingGpuHourOwned` | **blank** | Phase 0 |

---

## F. Deliberately excluded

No live identity, payments, inference, speech, avatar, social, age-assurance, or
record-anchoring service. No store integration, card form, or external link. No
real hotline routing beyond the sample card. No television footage, no network
material, and no synthesised likeness of any real person. No audio path at all:
voice is a set of simulated states and a metrics panel.
