# perSONA AI — high-fidelity prototype (v0.3)

Licensed AI versions of the personalities fans already follow, in a private
conversation that remembers them. This is the deck's **4K prototype** gate:
it behaves like the service, on a fully simulated backend, in one
self-contained file.

Open `index.html` in a browser. No build step, no dependency, no server, and no
network call of any kind.

| File | What it is |
| --- | --- |
| `index.html` | The prototype. ~796 KB, everything inline including SHA-256, the wordmark, and every icon. |
| `wireframe-v0.2.html` | The previous tappable wireframe, kept so the progression is traceable. |
| `CLAUDE.md` | The coding rules, carried from v0.1. Read before changing anything. |
| `ASSUMPTIONS.md` | Every unresolved decision, its default in this build, and who decides it. |
| `VERIFICATION.md` | The requirement-linked verification report. |

---

## What is new in this iteration

**TrainingStudio** — persona models, voice, and memory. Corpus with per-item
rights provenance; training runs that progress on the simulated clock; eval
gates that distinguish *safety* (blocking) from *quality* (warning); checkpoint
promote and rollback as recorded decisions; voice enrolment, a pronunciation
lexicon, and voice gates; an eval bench that runs the live engine against a
fixed prompt suite and compares two checkpoints; and a memory-review queue for
continual learning.

**AgentStudio** — create and deploy agents for the talent. Fourteen voice
registers from promotional to argumentative to crisis management, across sixteen
platforms. An agent builder that enforces its constraints while you build, a
human review queue, a per-platform connector table, a simulator, a coverage
matrix, and a crisis console with playbooks and a one-button freeze.

**The talent pipeline** — the real 90 Day roster as a business-development
record: sourced public facts, outreach logs, a six-artifact consent workflow,
and the franchise and market context behind the roster choice.

**The 4K design system** — two surfaces on one token set (a warm, intimate
*companion* surface for members; a denser *studio* surface for the talent side),
an onboarding flow, a command palette, notifications, light mode, higher
contrast, larger text, reduced motion, and a layout that runs from a 390 px
phone to a 3840 px display.

---

## The line this build draws, and where it is drawn

The whole product exists because of one promise from the deck: *no
participation, no persona*. In this iteration that promise is a code path with
self-checks, not a policy paragraph.

**Real, identifiable people appear in exactly one place: the talent pipeline.**
Sixteen named public figures from the 90 Day franchise are held there as sourced
business facts — which series they appeared in, what they have said publicly
about their own commercial plans, roughly how large their audience is, who owns
the relationship, and what would go wrong. Every fact carries the outlet that
reported it.

**They are never given a persona.** No biography, no invented quotes, no
personality profile, no dialogue, no voice enrolment, no memory, and no
first-person agent. Four guards enforce it, and `selfCheck()` asserts each one:

| Guard | What it refuses |
| --- | --- |
| `availabilityOf()` | A real person is unavailable for conversation even if the status field is forced to `approved`. |
| `adapters.licenses.setStatus()` | The rights dropdown refuses to approve a real name — that needs an executed agreement recorded in the consent workflow. |
| `agentVoiceMode()` | An agent bound to a real name can only speak as the team, and says so. First person is disabled in the builder, not hidden. |
| `personaCorpusReady()` / `voiceReady()` | Training and voice enrolment refuse a real person, a revoked or expired licence, and any corpus item whose rights are not cleared. |

**The personas you can actually talk to are invented.** Eleven fictional
characters with invented names, generated placeholder portraits, and franchise
tags — each one says so on its own detail screen. They are the only entries
whose licence status can reach `approved`.

**Big Ed** is carried exactly as the deck carries him: the proposed
demonstration personality, rights status `pending`, labelled "Proposed, not
licensed", absent from Discover, with no biography and nothing to talk to. His
record lives in the pipeline, at *in negotiation*, with the four things about
him that are actually on the public record.

The consent workflow shows the whole path to a licensed persona — six artifacts,
six owners — and stops at the one step the prototype cannot fake: approved
source material, which only the person can provide. That stop is the
demonstration.

---

## Walking it in ten minutes

1. Open the file. You land on the welcome flow; step two states what the product
   is before it shows a single personality.
2. `⌘K` / `Ctrl-K` opens the command palette — every screen, every personality,
   every pipeline record, and the demo actions.
3. **Demo controls** (bottom of the rail) holds the simulated clock,
   `LAUNCH_STATE`, `billingChannel`, the disclosure interval, and four seeded
   scenarios. **Seed a full member session** runs a waitlist join, a Pro
   checkout, three days of conversation, and a finished training run, then lands
   on Measurement.
4. **Discover → a companion → Start a conversation.** In the room, try the
   *demo intents* dropdown: it reaches every branch, including a talent-boundary
   refusal, a platform refusal, "are you really you?", something to remember, and
   a crisis trigger. Press **+1 hour** in demo controls to cross the disclosure
   interval.
5. **Talent studio → Pipeline** → open Big Ed → **Consent workflow**. Record the
   artifacts and watch where it stops.
6. **TrainingStudio** → pick Big Ed (blocked, with the reason) then Marisol Vega
   → **Start a training run** → advance the clock → the checkpoint appears and is
   *not* live → **Promote**. Try promoting one that fails a safety gate.
7. **AgentStudio → New agent.** Pick a pipeline prospect and watch first person
   disable itself. Pick *argumentative* and watch auto-publish disable itself.
8. **Coverage** → the matrix of every personality against every platform.
   **Fill every gap** deploys the default registers for everyone.
9. **Crisis console** → **Freeze everything**, then try to draft.
10. **The record** → verify the chain, then tamper with entry 2.

---

## How the file is organised

| Block | Contents |
| --- | --- |
| Brand | The wordmark as a data URI, the compact mark, and the icon table |
| Configuration | `OPERATOR`, `PLANS`, `DISCLOSURE`, `COST_MODEL`, `PLATFORMS`, `TONES`, `PLATFORM_POLICY`, `TOPICS` |
| Fixtures | The licensed roster, the real-name pipeline, the franchise, the market figures, policies, demo intents, crisis triggers |
| Strings | `STRINGS.en` keyed by screen and element; `STRINGS.es` deliberately empty |
| Core | SHA-256, canonical JSON, the seeded generator, the simulated clock, DOM helpers, generated portraits, the chart library |
| State | Named slices, persistence with a schema version, events, the record, the precedence engine, the entitlement reducers |
| Adapters | Twenty-one boundaries, one shape each, every one `mode: "mock"` |
| Engine | The deterministic conversation engine, the disclosure cadence, measurement |
| Training | Rights gates, run lifecycle, eval gates, voice, the memory queue |
| Agents | Voice mode, risk and approval, draft generation, coverage, incidents |
| Screens | Shell, member surface, the room, settings, then the five studio routes |
| Router | Hash routes, render, self-checks, the seeded session, boot |

**Routes.** `#/welcome`, `#/discover`, `#/companion/:id`, `#/waitlist/:id`,
`#/plans`, `#/account`, `#/profile`, `#/checkout`, `#/companions`,
`#/conversation/:id`, `#/community`, `#/settings`, `#/about`, `#/demo`, and
`#/studio/{pipeline,rights,training,agents,coverage,crisis,measurement,record}`.

**Console handle.** `window.__persona` exposes `state()`, `adapters`, `Record`,
`measure()`, `selfCheck()`, `Clock`, `reset()`, `seedDemoSession()`, `render()`,
`go()`, plus `agents.*`, `training.*`, and `guards.*`.

---

## Design notes

**Two surfaces, one token set.** Members get warm charcoal, 22–30 px radii,
large type, soft glows behind portraits, and the "remembers you" affordance on
the surface rather than buried — the audience for a companion product wants to
feel met, not administered. The studio tightens the geometry to 9–12 px, raises
the density, and switches to tabular numerals: a different job for a different
person.

**Charts.** The categorical palette is validated, not eyeballed: rose → violet →
green → blue clears every adjacent colour-vision gate in both light and dark
modes, and the first three clear all-pairs for cells and scatter. The brand
amber is chrome only and never a series colour; status colours are reserved and
always ship with an icon and a word. Every chart with two or more series carries
a legend, a selective direct label, and a table view.

**Accessibility.** Light mode is a selected set of steps rather than an
inversion. Higher contrast, larger text, and reduced motion are settings, and
the OS reduced-motion preference is honoured regardless. Switches carry
`aria-label`, images carry `alt`, the coverage matrix encodes status with a glyph
and a label as well as a colour, and focus rings are visible throughout.

---

## Build hygiene

- No external font, script, or stylesheet. No network call of any kind.
- Formatted with Prettier (printWidth 100); ESLint reports **zero errors** — the
  only warnings are four intentionally unused `catch` bindings around storage
  access, which must not throw.
- 796 KB, against the 1.5 MB ceiling.
- 31 acceptance scenarios and 25 in-file rule self-checks, all passing. See
  `VERIFICATION.md` for how they were run.

## Known limits

- `STRINGS.es` is empty on purpose; a missing key falls back to English so the
  localisation gap stays visible in review.
- Retention reads across a single prototype member, so it is 1 or 0 rather than
  a rate. The "Sample data" label is the honest part.
- The crisis screen is a fixture phrase list, not a classifier. It will miss real
  phrasing, which is exactly why production runs a real screen on the rack.
- No typeface is embedded (the no-network rule), so the wordmark is the supplied
  PNG and the interface uses a tightly tracked system stack beneath it.
- Platform capabilities are recorded as of September 2026 from public developer
  documentation. They change; the connector table is where to re-check them.
