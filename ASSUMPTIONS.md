# ASSUMPTIONS

Every unresolved decision in the v0.2 wireframe, the default this build carries,
and who decides it. Nothing in this list is settled. Where a value is blank, it
is blank on purpose: an invented number here would become a quoted number later.

Legend for **Owner**: *Company* = the talent-side operator (Tom's company);
*Armada* = the technology partner; *Counsel* = external counsel in both
countries; *Phase 0* = measured during the thirty-day gate, not decided by
anyone in advance.

---

## A. Added by the v0.2 addendum

| # | Decision | Default in this build | Owner |
| --- | --- | --- | --- |
| A-01 | Company working name | `{{COMPANY_NAME}}` — rendered as a visible token wherever the operator name appears, so no reviewer mistakes it for a chosen name. Legal entity: `TBD`. | Company |
| A-02 | Disclosure reminder interval | Production default 180 minutes; demo default 3 minutes so the simulated clock reaches it in one tap. Both live in `DISCLOSURE`. | Counsel (California SB 243, New York) |
| A-03 | Crisis trigger phrases | An eight-phrase demo fixture (`CRISIS_TRIGGERS`). This is **not** a production classifier and must not be described as one. | Counsel + Armada |
| A-04 | Age assurance vendor | Not chosen. `AgeAssuranceAdapter` returns `verified (demo)` from the M-03 checkbox and says on screen that production uses a vendor check. Only a state is ever stored, never a document. | Company (with Armada) |
| A-05 | Billing channel per platform | Fixture, switchable in the demo tray: `web`, `app_store`, `play`. Prices identical on all three. Commission is server-side and never shown to members. | Company |
| A-06 | Talent revenue share | Not shown in the member or creator UI in v0.1 or v0.2. The deck proposes 25 to 35 percent of net; that number appears nowhere in the product. | Company + participating talent |
| A-07 | Roster names | Eleven invented personas; one proposed real-name concept label (Big Ed / Ed Brown) at `pending` with no biography, quotes, or storylines. | Company |
| A-08 | Phase 0 metric definitions | Primary: paid conversion of a personality's waitlisted fans. Secondary: 30-day retention of paying members. Both computed in the Measurement panel from `events[]` only. | Company + Armada |
| A-09 | Owned-rack cost per conversation minute | **Blank** (`COST_MODEL.ownedRackPerMinute = null`). Renders as "not measured" in the cost table. | Phase 0 |

---

## B. Carried forward from v0.1 (as reconstructed)

The v0.1 brief was not supplied with this task. These entries are reconstructed
from the addendum's cross-references and the concept deck. If the real v0.1
states otherwise, it governs.

| # | Decision | Default in this build | Owner |
| --- | --- | --- | --- |
| B-01 | Plan prices | Entry US$6.95, Expanded US$14.95, Pro US$29.95 a month. Proposed, not validated by the market. | Company |
| B-02 | Entry selection count | Four selected personalities in total. | Company |
| B-03 | Entry swap frequency | **Unresolved.** No swap limit is enforced; releasing a selection is unrestricted and history survives. | Company |
| B-04 | Expanded entitlement | Four selections, carried as a prototype assumption only and labelled "Prototype assumption, not an approved entitlement" on the Plans screen. | Company |
| B-05 | Pro daily limit | Seven distinct personalities a day, counted when the first message is sent, reset on a provisional UTC day. Not seven simultaneous sessions. | Company |
| B-06 | The word "unlimited" | Used on Plans, immediately qualified: advertised in production only after Phase 0 has measured inference, voice, storage, licensing, and moderation on the rack. | Company + Phase 0 |
| B-07 | Cancellation | Access continues to the end of the paid period. One optional reason question; no countdown, no appeal, no mention of the companion. | Company |
| B-08 | Sign-in providers | Apple, Google, email — all simulated. No identity provider is contacted. | Company |
| B-09 | Voice in v0.1 | Six simulated states: idle, listening, processing, speaking, cancelled, failed. No audio is captured or played. Typing always works. | Armada |
| B-10 | Images | Members share still images only; no user video in scope. Placeholder portraits are generated SVG until approved assets exist. | Company |
| B-11 | Memory model | Per companion, inspectable, editable, disableable, deletable, owned by the member. Written from plain first-person statements in the demo engine. | Company |
| B-12 | Community | Fixture posts, labelled "Sample data". Nothing from a profile, interests, or a conversation appears there. | Company |
| B-13 | Territory and duration on licences | Fixture values per persona. Real terms come from the signed agreements. | Company + talent |
| B-14 | Retention windows for analytics | Not set. Declared in the analytics adapter as a policy decision. | Counsel |
| B-15 | Localisation | English only. `STRINGS.es` is an empty object so a missing key falls back visibly. | Company |

---

## C. Policy and legal

| # | Decision | Default in this build | Owner |
| --- | --- | --- | --- |
| C-01 | Policy wording | All six policies are **labelled outlines, not legal text**: Terms of Use, Community and Corporate Guidelines, Privacy Notice, AI Disclosure, Subscriptions and Cancellation, Reporting and Enforcement. | Counsel |
| C-02 | Governing law and dispute resolution | `TBD by counsel`, stated as such in the Terms outline. | Counsel |
| C-03 | Crisis resources by jurisdiction | United States sample only (988 Suicide and Crisis Lifeline, Crisis Text Line, emergency services), loaded from a fixture and labelled as a sample. Production loads counsel-approved resources per jurisdiction. | Counsel |
| C-04 | Record anchoring | The chain is local and verifiable. Whether it is anchored publicly is a production decision, declared in the record adapter and not decided here. | Company + Armada |
| C-05 | Report ticket state machine | Four states declared (received, in review, actioned, closed); the prototype issues tickets at `received` and does not simulate a queue. | Company |
| C-06 | Moderation staffing | Two to four people at launch per the deck, sized in Discovery. Not modelled in the product. | Company |

---

## D. Cost model inputs

`COST_MODEL` in `index.html`. Every figure it produces is labelled "Estimate, to
be measured in Phase 0."

| Field | Default | Source |
| --- | --- | --- |
| `tokensPerTurnPrompt` | 600 total per turn, split 420 prompt / 180 completion | Armada estimate; addendum default was 600 per turn |
| `speechSecondsPerReply` | 20 | Armada estimate |
| `rentedVoicePerMinute` | 0.08 | ElevenLabs published agent overage rate, September 2026, per the deck |
| `rentedLlmPer1kTokens` | **blank** | To be quoted |
| `ownedRackPerMinute` | **blank** | Phase 0 |
| `moderationMinutesPer1kMessages` | 12 | Armada estimate |

---

## E. Deliberately excluded

No live identity, payments, inference, speech, avatar, social, age-assurance, or
record-anchoring service. No store integration, card form, or external link. No
real hotline routing beyond the sample card. No 4K work. No television footage,
no network material, and no real likeness of any kind.
