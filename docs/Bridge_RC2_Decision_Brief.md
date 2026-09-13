---
title: Bridge™ · What to add for FEMSA · Decision brief for Release Candidate 2
audience: Internal, Armada. Not for the client. Contains node counts, model names and prices that must not leave the building.
prepared_by: Taylor, for M. David King and Daniel Graf
date: 2026-09-12
status: For decision. Six additions proposed for RC2, three items held for RC3 and later, five decisions requested.
inputs: Daniel Graf, Where Genesis best serves FEMSA, v0.2 (13 Sep 2026); the "Analyze Tech Stack" analysis Daniel shared (four screenshots, 12 Sep 2026); independent research pass (two sources per figure unless flagged); Bridge RC1 build and AUDIT.md (12 Sep 2026)
---

# 1 · The decision

Daniel's notes read Bridge RC1 as a feature map and place every tile inside FEMSA; the tech-stack analysis reads the same opportunity from the workflow side; the research pass checked both against public sources. They agree on the first process (supplier-side invoices and payments), on what an agent per store means (store-scoped agents on shared model services, not thousands of models), and on the pilot shape (one distribution centre, its stores, one workflow, measured). They differ on remittances, which the analysis treats as an early workflow and Daniel keeps out of the first conversation, and on the accountability argument, which only Daniel makes. The recommendation follows Daniel on both.

**Recommendation.** Build RC2 as the console for the CEO conversation and the first Discovery, nothing wider: six additions, three extensions of screens that exist and three new screens, in about three build sessions. Hold remittances, Salud and multi-tenant for RC3 and later. Ship a client demo mode first, because RC1 shows node counts, model names and Apple prices on screens that Daniel's rules say must not leave the building.

## The six additions

| # | Addition | Screen | Why now | Kind |
|---|---|---|---|---|
| 1 | Client demo mode: hides node counts, model names, bill of materials and prices; wording audit of every string that could read as fiscal validity or control remediation | Settings, all screens | Daniel's section 7; RC1 fails it today on Configuration, Latest models and the sidebar | extend |
| 2 | Match workspace: purchase order, receiving record, supplier CFDI and bank record side by side; one owning case; deterministic checks shown apart from agent findings | New screen: Match | The first process; the analysis's case model; 50 to 65 percent of invoices match cleanly first time | new |
| 3 | Pilot measures: Daniel's seven measures and the OXXO planogram number against published benchmarks | New screen: Measures | The Discovery is measurable or it is not a Discovery | new |
| 4 | Compliance clocks on Invoices: PPD or PUE, cancellation acceptance (three business days, the 24-hour window, 2026 express acceptance for REP), 69-B thirty-day evidence, an Article 84 exposure counter | Invoices, invoice page | Per-document penalties across tens of millions of CFDI; every one a dated record | extend |
| 5 | Stores and store-scoped agents: a Stores tile, an agent scoped to a store, supplier or route in AgentStudio, the planogram compliance template | New screen: Stores; AgentStudio step 1 | The layer FEMSA lacks between the planogram and 24,000 stores; the Discovery measurement if Daniel's open question resolves yes | new |
| 6 | Topology in Health: store connectors with offline queue state, regional cluster, central finance, recovery site with replication lag | Health | The analysis's deployment table; RC1 assumes console and cluster share a site | extend |

## Five decisions requested

| Decision | Owner | Default |
|---|---|---|
| Does the planogram agent go into the first Discovery as its measurement, or wait for a second? | Daniel | In, as the measurement; it is the only number FEMSA does not have |
| Does the ITGC evidence argument enter the CEO letter? | Daniel | No; it belongs to the comptroller conversation, and the letter should not read as a statement about FEMSA's controls |
| Which operating company hosts the first rack? | Both | OXXO Mexico for the planogram gap; Coca-Cola FEMSA is the second rack, for the control gap |
| Canonical figures: 24,455 or 24,708 OXXO stores; Spin users 29 million, 11.5 million active or 67.1 million acquired | Martin | Cite the FEMSA filing figure with its date on any surface; see section 7 |
| RC2 scope: the six additions, or the minimum (items 1 to 3) before the CEO letter | Both | All six; items 1 to 3 first so a demo is safe within one session |

# 2 · Where the inputs agree

| Point | Daniel v0.2 | Tech-stack analysis | Research |
|---|---|---|---|
| Supplier-side invoices and payments are the first process | yes | yes | yes |
| A private staff assistant with provenance answers the Copilot line | yes | | yes |
| An agent per store means store-scoped agents on shared models | yes | yes | yes |
| One owning case per cross-store exception; deterministic checks, agent investigation | | yes | yes |
| Four records: purchase order, receiving, supplier CFDI, bank record | | yes | yes |
| Store connector with offline queue, regional cluster, central finance, recovery site | | yes | yes |
| Pilot: one distribution centre, its stores, one workflow, measured | yes | yes | yes |
| Chain, Audit, Update as the evidence class behind the ITGC adverse opinion | yes | | |
| Remittances and settlement reconciliation as an early workflow | | yes | |
| Remittances, AML and credit stay out of the first conversation; Spin last | yes | | |
| Planogram compliance agent per store as the Discovery measurement (open) | yes | | |

**What the analysis adds that Daniel's notes do not:** the case model (four records answering four questions; deterministic controls enforce arithmetic, identifiers, tolerances, permissions and duplicate prevention while the agent investigates); the refinement that two agreeing sources may be copies of the same wrong source; the rule that an ambiguous timeout is never permission to pay again; the deployment table with the offline queue at the store. All four go into RC2. Its sensitivity arithmetic (0.05 percent of an eligible MXN 100 billion flow is MXN 50 million before costs) is arithmetic, not a claim, and stays out of client material.

**What Daniel's notes add that the analysis does not:** the map from every tile to a division and a sequence; the accountability layer as the evidence class behind FEMSA's two adverse opinions on internal control, with the honest limit that a seal proves what was recorded was not altered and never that everything was recorded; the ladder from a four-node pilot to a rack per division; the objections; and the section 7 rules that RC1 does not yet obey.

# 3 · Capability map

Bridge screens against the six FEMSA needs. built = fits as is · extend = RC2 extension · new = RC2 new screen · hold = RC3 or later · blank = not for this need.

| Screen | Supplier invoices | Store cash and settlement | Remittances | Planogram per store | ITGC evidence | Staff assistant |
|---|---|---|---|---|---|---|
| Invoices | extend | | | | | |
| Collections | built | | | | | |
| Agents, AgentStudio | extend | | | new | | |
| Chat (Taylor) | | | | | | built |
| Chain, Audit | built | built | hold | built | extend | |
| Update | | | | | built | |
| Policies | built | | | extend | built | built |
| Data (ARCO) | | | hold | | | |
| Roles | built | built | built | built | built | built |
| APIs | extend | hold | hold | extend | | |
| Health, Node | | | | extend | | |
| Energy | | | | | | |
| Incidents | extend | hold | hold | extend | | |
| Models, Latest | | | | | | built |
| Configuration | extend | | | extend | | |
| Installer | built | built | built | built | built | built |

Energy fits no FEMSA need in this brief and stays as built: it is the Phase 1 option for a division cluster and the argument for the store network where the grid is weak. Data with its two-custodian ARCO flow is the Spin feature, and Spin is last, so it stays as built and is not demonstrated first.

# 4 · The first process, drawn

Purchase order (what was authorized) · Receiving record (what arrived) · Supplier CFDI (what was billed) · Bank record (what was paid) → **one owning case** (tolerances, identifiers, duplicate check, permissions; deterministic first, the agent investigates the rest) → **exception queue** (one per division, sealed) → **approval gate** (typed word, authenticator; never pay again on a timeout). Actions the case may take, in FEMSA's approval order: draft the supplier inquiry, request missing delivery evidence, flag a receiving mismatch, route to the regional team. The permitted accounting action follows FEMSA's policy; the agent recommends, the person decides, the chain records both.

**What the Match screen shows.** A case opens when a supplier CFDI arrives or a receiving record disagrees with an order. The four records sit side by side with the fields that must agree highlighted: quantities, unit prices, totals, tax, RFC, UUID. Deterministic checks run first and show as green or red lines with the rule that produced them (tolerance, duplicate UUID, cancelled at SAT, issuer on the 69-B list). Only what remains goes to the agent, which writes the finding and the recommended action in plain words, and every recommendation carries the guardrails version it was written under. The case has one owner even when several store agents contributed evidence, so two agents can never open two disputes on one invoice.

**The capacity consequence.** Parsers and deterministic services carry the invoice XML and the straightforward matches; model reasoning is reserved for ambiguous documents, explanations and exceptions. That moves most touches off the Kimi octet and onto rules, which is why the Configuration planner gains a documents-per-day input in RC2 that converts to heavy touches before it converts to octets.

# 5 · Deployment, and what Health must learn

Store (Bridge interface; lightweight connector with a protected offline queue) → Regional facility (shared Génesis clusters serving store workloads and regional investigators) → Central finance (cross-store reconciliation, supplier cases, settlement and approval controls) → Recovery site (replicated state and tested recovery capacity).

RC1 today: one rack, one health map, one power spine, one store of records; every screen assumes the console and the cluster share a site. RC2 adds a topology view in Health: stores as tiles with their connector's queue state (online, queued, syncing), the regional cluster they report to, the central finance node, and the recovery site's replication lag. The cluster map already built becomes one tile inside it. Store count alone never sets the number of clusters: placement follows measured latency, connectivity, data isolation and resilience, which the view records per site.

# 6 · Measures and benchmarks

The Measures screen carries Daniel's seven measures plus the OXXO number: correct automatic matches and false matches; exceptions resolved without human intervention; human minutes per case; time to resolve discrepancies; confirmed duplicate payments or missed credits; cost per processed case; recovery behavior and evidence completeness; planogram compliance rate per store (the Discovery number). Every card is computed from the store and labeled EST until the pilot measures it.

Benchmarks the cards are read against (Ardent Partners 2025 via Corpay and Parseur; APQC; IOFM): cost per invoice $9.40 average, $2.78 best in class; exception rate 14 percent average, 9 percent best in class; cycle time 9.2 days average, 3.1 best in class; touchless 32.6 percent average, 49.2 percent best in class; invoices matching cleanly first time 50 to 65 percent; duplicate payments 0.8 to 2 percent of disbursements.

# 7 · Facts to canonize before anything leaves the building

| Figure | Daniel's notes | Research (two sources unless flagged) | Action |
|---|---|---|---|
| OXXO stores in Mexico | 24,708 | 24,455 at 31 March 2026 (Mexico News Daily; FEMSA 20-F: 1,125 net new stores in 2025 from 23,206). 25,587 worldwide in 2025 (FEMSA annual report) | Cite the filing figure with its date; if 24,708 is a June 2026 figure, add its source |
| OXXO tickets per day | 13 million | 13 million (FEMSA annual report 2025; Mexico News Daily 2026) | Canon |
| REP deadline | day five of the following month | Fifth calendar day of the following month, RMF rule 2.7.1.32; calendar days, not business days (SenHub 2026; Tesio 2026; Savio) | Canon; Bridge's clock already counts to day five |
| Penalty for a missing complement | MXN 450 to 670 per comprobante, Article 84 CFF, 2026 amounts | Infraction under Article 83, amounts under Article 84 (SenHub; Recuperafacturas); the peso range is single-source in this brief | Keep both article numbers; verify the 2026 range against the DOF before it appears on a screen |
| Cancellation acceptance | not stated | Three business days; silence is acceptance; a 24-hour no-acceptance window; from 2026 CFDI with a payment complement need express acceptance (Fiscalapi; Solución Factible; CodigoNext; Tesio) | Add to the Invoices clocks in RC2 |
| RELEX scope at OXXO | forecasting and replenishment, 2023 to 2024 | Selected September 2023, pilot on 13 categories at 60 percent of sales, go-live April 2024, then replenishment (RELEX case study; Business Wire 2023 and 2024) | Canon |
| Spin users | 29 million Spin Premia active users | Spin by OXXO 11.5 million active users and 119.1 million transactions a month in Q2 2026; Spin Premia 67.1 million acquired users (Zacks via TradingView; Rio Times) | Name the metric on every surface; the three numbers measure different things |
| Solística sold to Traxión, 1 July 2025 | stated | Not verified in this pass | Verify with two sources before it enters client material |
| AP benchmarks | not used | Best-in-class $2.78 per invoice, 9 percent exceptions, 3.1-day cycle, 49.2 percent touchless (Ardent Partners 2025); duplicates 0.8 to 2 percent (APQC; IOFM) | Use as the benchmark bars on Measures, dated |
| Sixty-four nodes; ten million invoices a day | must not appear | Neither appears in Bridge RC1 | Keep it so; the demo mode also hides the 17 |

# 8 · Held for RC3 and later, and why

| Candidate | Carries | Sessions |
|---|---|---|
| RC2 · the CEO conversation and the first Discovery | Client demo mode and wording audit · Match workspace with one owning case · Pilot measures · Compliance clocks · Stores and store-scoped agents · Topology view | 3 |
| RC3 · the first rack in a division | Division inheritance of guardrails · store cash and settlement reconciliation · evidence packs for the comptroller · Portuguese | 3 |
| RC4 and later · regulated ground | Remittances reconciliation · FEMSA Salud documents · multi-tenant estate (not canon, not priced) | 4 |

Remittances and store settlement are credible workflows and the analysis draws them well, but nothing touching remittances, anti-money-laundering or credit belongs in the first conversation, and a console that shows a remittance reconciliation screen invites exactly that conversation. FEMSA Salud is high sensitivity and needs its own rules. The multi-tenant estate is not canon and not priced.

# 9 · What RC2 must not do

| Rule (Daniel, section 7) | Where RC1 breaks it | RC2 fix |
|---|---|---|
| No node counts before a signed discovery agreement | Sidebar footer, Health (17 nodes), Configuration (9, 17, 25), Installer (17 found) | Demo mode replaces counts with "the rack" and hides Configuration's node axis |
| No model names | Models, Latest models, Installer step 5, node role labels (Kimi shard, Llama 4) | Demo mode shows "escalation model" and "routine model"; catalog hidden |
| No bill of materials, no prices | Configuration shows Apple list prices and totals | Configuration hidden in demo mode; planner stays for internal use |
| Power in kilowatts, no appliance comparison | Energy pages comply | None |
| The seal witnesses the stamp; it never confers fiscal validity | No string claims validity | Wording audit script over every L() pair; a test that fails on "valid" near "sealed" |
| No claim the layer remediates a control | No such string in RC1 | Audit screen subtitle gains the honest limit: proves what was recorded was not altered, not that everything was recorded |
| No claim an agent decides alone | AgentStudio and every agent card say a person decides | Match screen repeats it on the approval gate |
| No collections or compliance result before one is measured | Agent cards show reply rates and handoffs from seed data | Demo mode labels every figure "sample data" |

# 10 · Sources

FEMSA Form 20-F FY2025 (SEC, 2026); FEMSA Integrated Annual Report 2025; FEMSA press release on the 2025 report (2026); Mexico News Daily, OXXO in numbers (2026); Opportimes on OXXO growth (2025); RELEX case study on OXXO and Business Wire releases (2023, 2024, 2025); Western Union Corporate and Business Wire on OXXO remittances (2024); Remitly and Western Union provider pages; Miranda Intelligence (2023, single source for the Spin partner roster); BBVA Research and Mexico News Daily on 2025 remittances; SenHub (2026), Tesio (2026), Savio and Recuperafacturas on the REP; Fiscalapi, Solución Factible and CodigoNext (2026) on cancellation; Corpay, Parseur and Nexus AP on Ardent Partners 2025 and APQC; Trustmi (APQC) and IOFM on duplicate payments; AWS Architecture Blog, Actian and Avassa on offline-first edge patterns; FEMSA Forms 6-K (2025, 2026), Zacks via TradingView and Rio Times on Spin; Daniel Graf, Where Genesis best serves FEMSA, v0.2, 13 September 2026; the Analyze Tech Stack analysis shared by Daniel, 12 September 2026; Bridge RC1 build and AUDIT.md, 12 September 2026.
