# Coding rules for this repository

These are the rules set at v0.1 and carried through every iteration. They are
not stylistic preferences; each one exists because breaking it would make the
prototype misrepresent something. Read this before changing `index.html`.

## The build

1. **One self-contained file.** The deliverable is a single `index.html` that
   opens from the filesystem. No build step, no bundler, no package manager.
2. **No network call, ever.** No external font, script, stylesheet, image, or
   API. SHA-256, every icon, the wordmark, and all art are inline. If a feature
   needs a network, it gets a mock adapter and a documented contract instead.
3. **Deterministic simulation.** One seeded generator (`RNG_SEED`), one
   simulated clock (`CLOCK_EPOCH`). Two runs of the prototype produce the same
   roster order, the same ids, and the same measurements.
4. **Size ceiling 1.5 MB**, including fixtures and the inlined wordmark.
5. **Formatter and linter before delivery.** Prettier (printWidth 100) and
   ESLint. Zero errors. The only acceptable warnings are unused `catch (e)`
   bindings around storage access, which must not throw.

## The code

6. **T-04 comment convention.** Every block comment opens with the requirement
   IDs it serves and says *why* the rule exists — never what the next line does.
   No commented-out code.
7. **Text nodes only.** User content is written with `textContent`. `innerHTML`
   is used only for literal inline SVG authored in this file, and only in the
   icon, avatar, and favicon helpers.
8. **One `state` object with named slices**; entitlement and rights transitions
   live in pure reducers; rendering is one function per screen behind a hash
   router. Persistence carries a `schemaVersion` and a migration stub, and one
   reset function clears everything.
9. **Every service behind the adapter registry**, each entry declaring
   `mode: "mock"`, its proposed contracts (method, input, output, expected
   errors, authorisation, sensitive fields, caller), and where the real
   implementation runs — `rack` (hardware the operator owns) or `vendor`.
10. **Self-checks, not prose.** A rule that can be checked in a pure function is
    checked in `selfCheck()` and rendered on the About screen.

## Honesty

11. **Label every simulated figure.** "Sample data" for seeded counts,
    "Estimate, to be measured in Phase 0" for cost models, "As reported" for
    figures taken from a published source.
12. **Never invent a measurement.** An unmeasured unit assumption stays `null`
    and renders as "not measured". A guessed number here becomes a quoted number
    in a pitch.
13. **Cite every fact about a real person or a real platform.** Public facts
    carry the outlet and the date. Platform capabilities record what the
    platform actually exposes, including when the honest answer is "no API".
14. **Never invent test output.** A scenario is reported as passed only if the
    Playwright driver asserted it against the real file in a real browser.

## The line on real people

15. **Real, identifiable people appear only in the talent pipeline**, as sourced
    business facts. They are never given a persona, a biography, invented
    dialogue, a voice, a memory, or a first-person agent.
16. **Conversation, voice, and in-persona posting require
    `license.status === "approved"`,** which no real name holds. The guard is
    `availabilityOf()` plus `RIGHTS_GATE()`, and `selfCheck()` asserts it stays
    unreachable even if the status field is forced.
17. **An agent speaks in the first person only for an approved licence with a
    name-and-likeness grant.** Everything else speaks as the team and discloses
    it. `agentVoiceMode()` is the only place that decides.
18. **High and critical voice registers cannot auto-publish.** Not a default —
    the setter refuses. Critical needs two named approvals.
19. **Private conversations are never training data.** The continual-learning
    queue receives a de-identified copy only from a member who opted in
    specifically, and the studio cannot flip that default.
20. **The record stores identifiers, versions, and statuses only** — never
    message text, draft bodies, incident content, images, or private interests.
    Deletion leaves tombstones so the chain still verifies after erasure.

## Requirement IDs

Preserve them. `S-` plans, `M-` member journey, `C-` creator, `T-` technical,
`P-` production, `D-` deck-driven, `R-` regulatory and safety, `K-` the record,
`L-` the rights model, `V-` adapters and code structure, `G-` the rights guards
added in v0.3. `VERIFICATION.md` maps each one to where it lives.

## What is never built without being asked

No live identity, payments, inference, speech, avatar, social, age-assurance, or
record-anchoring service. No store integration, card form, or external link. No
real hotline routing beyond the sample card. No television footage, no network
material, and no synthesised likeness of any real person.
