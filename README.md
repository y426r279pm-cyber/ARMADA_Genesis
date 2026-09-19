# perSONA AI — high-fidelity prototype (v0.5)

Licensed AI versions of the people fans already follow — met once a day as a
group, any time one to one, and now face to face on a licensed video call. This is the deck's **4K prototype** gate: it
behaves like the service, on a fully simulated backend, in one self-contained
file.

Open `index.html` in a browser. No build step, no dependency, no server, and no
network call of any kind.

> **It must be opened by a browser, not by a preview pane.** The whole interface
> is painted by script from this one file, so a viewer that does not run scripts
> — an email client, a chat preview, an in-app file viewer — shows nothing at
> all. Save the file and double-click it, or drag it onto a browser window. If
> the script is blocked or fails, the page now says so in place and gives the
> reason; it can no longer come up empty.
>
> If you have opened an earlier build at the same address, the stored state from
> it is reseeded automatically on first load — `SCHEMA_VERSION` gates it, and a
> missing slice is seeded rather than allowed to break boot.

| File | What it is |
| --- | --- |
| `index.html` | The prototype. 1.19 MB, everything inline including SHA-256, the wordmark, and every icon. |
| `wireframe-v0.2.html` | The original tappable wireframe, kept so the progression is traceable. |
| `CLAUDE.md` | The coding rules, carried from v0.1 and extended at each iteration. Read before changing anything. |
| `ASSUMPTIONS.md` | Every unresolved decision, its default in this build, and who decides it. |
| `VERIFICATION.md` | The requirement-linked verification report. |

---

## What is new in this iteration

v0.5 adds **video presence**: a licensed video call with a talent's approved
likeness and voice, on-demand inside hours the talent sets.

**The call.** Full-bleed, five controls, no shell. A disclosure gate first,
stating in the negative that this is *not* the person and they are *not* on the
call. During the call the AI label is permanent and cannot be dismissed. Minutes
are an allowance shown before and after, never a meter ticking during an
intimate conversation, and nothing on the call screen sells anything.

**The look mixer.** The member styles setting, time of day, wardrobe and
framing — but only from the menu the talent curated. Face, body, age, voice and
mannerisms are fixed by the licence, and the panel says so rather than quietly
omitting the controls. A withheld option shows locked with a padlock, not
hidden: a padlock says a person made a choice.

**The crisis hold on video.** The persona stops mid-thought, the frame dims and
desaturates rather than cutting to black, and the platform speaks in its own
voice. The call is **not** ended and the member is **not** ejected. "Keep
talking here" returns to text in grounded mode rather than to the face. Nothing
of the disclosure reaches memory, the record or "Your week".

**Rig ingest.** The rig is built off-platform by a vendor and delivered. Nothing
here creates a likeness — it receives one, runs the rights checks automatically,
diffs it against the live version, and refuses to publish without a named human.
The diff is the review: rights checks catch a lapsed licence, not a vendor
quietly adding two expressions nobody agreed to.

**The Talent Care agent.** An agent pointed at the talent rather than the
public. It tracks a freshness clock, nudges in a warm professional register,
escalates to the manager of record, disables video at ninety days — and then
*recommends* a hold that only a named human can confirm. De-escalation is total:
one substantive update clears the ladder, with no probation and no memory of
having been chased. The guilt ban covers its outbound copy too, and that is now
a self-check.

**The script library.** How "gossip, set news and insider info" becomes
shippable. A talent's own withheld story clears. A line naming a real person who
signed nothing is blocked until that person's own written clearance is recorded
— and "my ex-husband" counts as a name. The persona can only say what is
cleared; there is no generative path to insider content.

**The lexicon, settled.** Six words were doing the work of three. Now: **member**
(who pays), **talent** (who signs), **persona** (what is built and versioned),
**companion** (a member's own instance). On a call, none of them appear — the
screen shows the name. Retrofitted across every existing screen, not just the
new ones.

**Removed.** The relationship-depth percentage. A progress meter on an intimate
relationship is the pattern this product is designed against, and nothing
replaced it.

---

## What was new in v0.4

v0.4 comes from a review of four products that have already found the parts that
work — Replika, Character.AI, Kindroid, Cameo — and is designed against the
parts that do not.

**The Cohort** is now the home screen. The member's companions are gathered in
one group room, seeded once a day with a thread from a fixture calendar
(episode nights, franchise anniversaries, the week ahead). Each companion
contributes **once**, in a turn order that rotates by day, so the room never
floods. A companion can be muted in the group without leaving the cohort, and
continuity between the group room and a private room follows an explicit
shared-memory toggle that is **off until the member turns it on**.

**Memory the member can see and shape.** Every remembered fact is an editable
card carrying the message it came from. Any message carries *Remember this* and
*Forget this*. A *Rewind* lifts and replays the last ten messages; a *Fresh
start* clears the short-term context and leaves every long-term fact standing.
Six categories — crisis disclosures, health, abuse, finances, immigration
status, and anything the member marks private — are **never written to memory at
all**, which is the structural answer to a companion that never forgets a
vulnerability.

**Moments**, stitched in from Cameo. Three fulfilment tiers, each labelled on
the delivered item: an **Instant AI Moment** inside approved boundaries,
delivered in the session and labelled AI-generated; a **Reviewed AI Moment**
that queues to the creator app, where the talent approves, edits, or
declines within four days; and a **Recorded Moment**, a real recording delivered
within seven days or automatically refunded. Delivered Moments live on a shelf,
sharing is a member choice, and a shared Moment never carries private
conversation content.

**The creator app.** A Requests inbox with accept, edit, and decline — decline
needs no reason and is not charged — plus price and availability controls, an
expiry countdown, earnings on sample data, and the safety tools that matter:
block a member, report harassment, boundary-breach alerts, a Reviewed preview
before release, an impersonation takedown form, and a **persona-level pause**
that ends availability immediately and writes to the record.

**Persona Studio.** Definition in the talent's own words, greeting,
backstory, approved and excluded topics, four plain-language sliders, a licensed
voice selection, approved stills, sample dialogues, an in-character test chat,
and a six-item checklist the talent completes before anything publishes.
Every published change is versioned into the record.

**Activities**, because a reason to open the app should not be the relationship
itself: a daily prompt, an episode-night room, a pep-talk request, a private
journal sealed by default, and mood check-ins that are optional, private, and
never read by retention logic.

**The crisis experience**, rebuilt from the ground up — see below.

---

## The crisis experience

The goal is an experience that feels comforting and confident: the member is
*met*, not *managed*, and the app knows what happens next and says so.

On a trigger the **persona steps back**: the avatar dims, playback stops, and it
sends nothing further. A platform-voiced sheet rises from the bottom over about
half the screen. It is a **sheet, not a takeover** — the transcript stays
visible behind it and the composer stays available above it. No sound plays.

The card speaks as the platform, never as the persona, in two lines and three
actions:

> Thanks for telling us. Let's slow this down together.
> You can talk to a person right now. It's free and it's confidential.

**Talk to a person now** · **Keep talking here** · **I'm okay** — and a fourth
line, *Text [name]*, if the member saved a trusted contact. Off-white on deep
teal. No red, no warning icon, no illustration, no question that forces a
disclosure, no lecture, no symptom list, no clinical label, and no mention of
the member's subscription. An optional *Take a minute* opens a sixty-second
breathing pacer with no score.

Choosing **Keep talking here** returns the companion in a **grounded mode**:
warm, present, brief. It reflects and stays. It asks no probing questions, never
role-plays, never claims to be a person, never expresses love or dependence, and
every few turns restates in one line that a person is available now. A *Help is
here* chip stays at the top of the transcript. There is no lockout and no time
limit; the member decides when to leave.

Afterwards, the disclosure reaches **neither persona memory nor group memory**.
The record gets a `moderation_action` with no text. No plan or upgrade prompt
appears anywhere for the configured window. "Your week" never mentions it.

When the screen is *unsure*, there is no card at all — just a soft chip above
the composer. "I'm okay" returns the session to normal with no penalty and no
repeat.

The screen is a keyword fixture, not a classifier, and the prototype says so.
That is exactly why production runs a real screen on the rack.

---

## The line this build draws, and where it is drawn

The whole product exists because of one promise from the deck: *no
participation, no persona*. It is a code path with self-checks, not a policy
paragraph.

**Real, identifiable people appear in exactly one place: the talent pipeline.**
Sixteen named public figures from the 90 Day franchise are held there as sourced
business facts — series credits, what they have said publicly about their own
commercial plans, an audience band, who owns the relationship, and what would go
wrong. Every fact carries the outlet that reported it.

**They are never given a persona.** No biography, no invented quotes, no
persona profile, no dialogue, no voice enrolment, no memory, and no
first-person agent. Five guards enforce it, and `selfCheck()` asserts each one:

| Guard | What it refuses |
| --- | --- |
| `availabilityOf()` | A real person is unavailable for conversation even if the status field is forced to `approved`. |
| `adapters.licenses.setStatus()` | The rights dropdown refuses to approve a real name — that needs an executed agreement recorded in the consent workflow. |
| `agentVoiceMode()` | An agent bound to a real name can only speak as the team, and says so. First person is disabled in the builder, not hidden. |
| `personaCorpusReady()` / `voiceReady()` | Training and voice enrolment refuse a real person, a revoked or expired licence, and any corpus item whose rights are not cleared. |
| `personaStudioAllows()` | New in v0.4 — the Persona Studio will not open a definition, a slider, or a test chat for a real name. |

**The personas you can actually talk to are invented.** Eleven fictional
characters with invented names, generated placeholder portraits, and franchise
tags — each one says so on its own detail screen. They are the only entries
whose licence status can reach `approved`.

**Romance modes do not exist here.** Friend, mentor, and confidant are offered;
romance requires a grant that no real person holds, and the control shows why
rather than hiding.

**Big Ed** is carried exactly as the deck carries him: the proposed
demonstration persona, rights status `pending`, labelled "Proposed, not
licensed", absent from Discover, with no biography and nothing to talk to. The
consent workflow shows the whole path to a licensed persona — six artifacts, six
owners — and stops at the one step the prototype cannot fake: approved source
material, which only the person can provide. That stop is the demonstration.

---

## Walking it in ten minutes

1. Open the file. You land on the welcome flow; step two states what the product
   is before it shows a single persona.
2. `⌘K` / `Ctrl-K` opens the command palette — every screen, every persona,
   every pipeline record, and the demo actions.
3. **Demo controls** (bottom of the rail) holds the simulated clock,
   `LAUNCH_STATE`, `billingChannel`, the disclosure interval, and the seeded
   scenarios. **Seed a full member session** runs a waitlist join, a Pro
   checkout, three days of conversation, and a finished training run.
4. **Cohort.** Read the day's thread, mute a companion and watch it fall silent
   in the group but keep answering in its own room. Turn shared memory on and
   watch the recall appear — then watch it fade after four exchanges.
5. **Open a companion → Memory.** Remember something, forget it, rewind, then
   fresh start and check the long-term facts survived. The sensitive-category
   list is on the same screen, with what it will never store.
6. In a room, use the *demo intents* dropdown: it reaches every branch,
   including a talent-boundary refusal, a platform refusal, "are you really
   you?", something to remember, an **uncertain** signal, and a **crisis**
   trigger. Try *Keep talking here* and read what grounded mode will and will
   not say.
7. **Ask for a Moment** on any companion detail. Take the Instant tier for the
   in-session version; take Reviewed and go to **Talent studio → Requests** to
   approve it as the persona; take Recorded, then push the clock past seven
   days and watch the refund arrive by itself.
8. **Talent studio → Persona Studio.** Pick a pipeline prospect and watch it
   refuse. Pick Marisol Vega and publish a version — then find it in the record.
9. **Talent studio → Requests → Pause this persona.** Go back to the Cohort and
   see it gone, with the room read-only.
10. **The record** → verify the chain, then tamper with entry 2. **About** →
    read all thirty-nine self-checks.

---

## How the file is organised

| Block | Contents |
| --- | --- |
| Brand | The wordmark as a data URI, the compact mark, and the icon table |
| Configuration | `OPERATOR`, `PLANS`, `DISCLOSURE`, `COST_MODEL`, `PLATFORMS`, `TONES`, `PLATFORM_POLICY`, `TOPICS` |
| v0.4 configuration | `COHORT`, `THREAD_CALENDAR`, `SENSITIVE_CATEGORIES`, `PROHIBITED_COPY`, `SAFEGUARDS`, `COMPANION_MODES`, `RETENTION`, `MOMENT_TIERS`, `ACTIVITIES`, `PERSONA_SLIDERS`, `CRISIS_COPY`, `GROUNDED_LINES` |
| Fixtures | The licensed roster, the real-name pipeline, the franchise, the market figures, policies, demo intents, crisis triggers |
| Strings | `STRINGS.en` keyed by screen and element; `STRINGS.es` deliberately empty |
| Core | SHA-256, canonical JSON, the seeded generator, the simulated clock, DOM helpers, generated portraits, the chart library |
| State | Named slices, persistence with a schema version, events, the record, the precedence engine, the entitlement reducers |
| Adapters | Twenty-eight boundaries, one shape each, every one `mode: "mock"` |
| Engine | The deterministic conversation engine, the disclosure cadence, measurement |
| v0.4 engine | `screenTurn`, `groundedReply`, `sensitiveCategoryOf`, `seedCohortThread`, `upgradePromptsAllowed`, `weekSummary` |
| Training | Rights gates, run lifecycle, eval gates, voice, the memory queue |
| Moments | Request, creator decision, acceptance, the refund tick, earnings, persona profiles and the pause |
| Agents | Voice mode, risk and approval, draft generation, coverage, incidents |
| Screens | Shell, member surface, the room, cohort, Moments, activities, settings, then the studio routes |
| Video | The call state machine, minutes, the availability window, the suggestive band |
| Likeness | Rig ingest and its checks, the mixer, the disclosure |
| Talent health | The freshness clock, the care agent's ladder, the script library |
| Router | Hash routes, render, fifty-one self-checks, the seeded session, boot |

**Routes.** `#/call/:id`, `#/minutes`, `#/welcome`, `#/cohort`, `#/discover`, `#/companion/:id`,
`#/waitlist/:id`, `#/plans`, `#/account`, `#/profile`, `#/checkout`,
`#/companions`, `#/conversation/:id`, `#/community`, `#/moments`,
`#/activities`, `#/week`, `#/settings`, `#/about`, `#/demo`, and
`#/studio/{pipeline,rights,persona,rig,likeness,freshness,care,update,scripts,videosafety,requests,training,agents,coverage,crisis,measurement,record}`.

**Console handle.** `window.__persona` exposes `state()`, `adapters`, `Record`,
`measure()`, `selfCheck()`, `Clock`, `reset()`, `seedDemoSession()`, `render()`,
`go()`, plus `agents.*`, `training.*`, `guards.*`, `cohort.*`, `moments.*`,
`persona.*`, and `safeguards.*`. The v0.5 call, likeness and care functions are
reachable as globals on the page for the same reason.

---

## Design notes

**Two surfaces, one token set.** Members get warm charcoal, 22–30 px radii,
large type, soft glows behind portraits, and the "remembers you" affordance on
the surface rather than buried — the audience for a companion product wants to
feel met, not administered. The studio tightens the geometry to 9–12 px, raises
the density, and switches to tabular numerals: a different job for a different
person.

**A third surface, used once.** The crisis sheet has its own palette — deep teal
on off-white — and it is the only place in the build that uses it. It is
deliberately not the product's surface: when the platform steps in, it should
look like the platform stepping in.

**Charts.** The categorical palette is validated, not eyeballed: rose → violet →
green → blue clears every adjacent colour-vision gate in both light and dark
modes, and the first three clear all-pairs for cells and scatter. The brand
amber is chrome only and never a series colour; status colours are reserved and
always ship with an icon and a word.

**Accessibility.** Light mode is a selected set of steps rather than an
inversion. Higher contrast, larger text, and reduced motion are settings, and
the OS reduced-motion preference is honoured regardless. It reaches the
breathing pacer too: the ring stops expanding and the pacer becomes a plain
sixty-second count, which is the right answer for someone who asked for no
motion. Switches carry `aria-label`, images carry `alt`, the coverage matrix
encodes status with a glyph and a label as well as a colour, and focus rings are
visible throughout.

---

## Build hygiene

- No external font, script, or stylesheet. No network call of any kind.
- Formatted with Prettier (printWidth 100); ESLint reports **zero errors** — the
  only warnings are three intentionally unused `catch` bindings around
  `localStorage`, which must not throw.
- 1.19 MB, against the 1.5 MB ceiling.
- **27 of 27** acceptance scenarios and **51 of 51** in-file rule self-checks
  pass, across **41** routes, with no console error. See `VERIFICATION.md` for
  how they were run and for the defects they found.

## Known limits

- `STRINGS.es` is empty on purpose; a missing key falls back to English so the
  localisation gap stays visible in review.
- The crisis screen and the sensitive-category matcher are keyword fixtures, not
  classifiers. They will miss real phrasing, which is exactly why production
  runs a real screen on the rack.
- Crisis resources are a **United States sample only**. Mexico is in scope for
  the business and has no resource card here.
- Retention reads across a single prototype member, so it is 1 or 0 rather than
  a rate. The "Sample data" label is the honest part.
- Moment prices, the 70 percent share, the four-day review window, the seven-day
  delivery window, the sixty-minute time notice, and the blackout window are all
  proposals recorded in `ASSUMPTIONS.md`, not decisions.
- No Moment is actually recorded: the creator app's record step is a
  placeholder, and no media file exists anywhere in the build. Group Moments and
  live calls are labelled placeholders.
- **No video exists.** A call is a state machine on the seeded clock: no camera
  is opened, no frame is rendered, no audio is produced, and no media file of
  any kind is in the build. The persona on a call is a labelled placeholder,
  because this prototype never synthesises a real person's likeness.
- The suggestive band, the third-party detector, the crisis screen and the
  sensitive-category matcher are keyword fixtures — not classifiers, not entity
  resolvers. Each screen says so. The suggestive band in particular ships
  deliberately conservative and labelled as under-tuned.
- Screen recording cannot be prevented on a general-purpose device. It is
  detected where the platform allows and named in the talent's agreement as a
  known limit, rather than claimed as solved.
- Three of the four video cost lines are blank and render as "not measured" or
  "to be quoted". A per-minute video cost is the number the owned-rack case
  rests on, so it waits for Phase 0.
- Group video calls are a labelled placeholder. The daily cohort was designed
  for text, and four companions on one call is a different product.
- No typeface is embedded (the no-network rule), so the wordmark is the supplied
  PNG and the interface uses a tightly tracked system stack beneath it.
- Platform capabilities are recorded as of September 2026 from public developer
  documentation. They change; the connector table is where to re-check them.
