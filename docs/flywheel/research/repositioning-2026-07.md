# Flywheel Repositioning: Modular Governance & Platform Immunity (2026-07)

> **"Heroes come and go; policies compound."**  
> *Flywheel is an unbundled, repository-resident governance micro-kernel and cognitive command center built for Engineering Leads.*

---

## 1. Executive Summary: The Platform Absorption Reality

### The Vendor Negligence Trap
A common strategic error in AI tooling is assuming vendor platforms "will never ship feature X." **Vendor negligence is not a moat; it is a countdown.**

Platform vendors (Anthropic, OpenAI, Google) already ship native subagents, fresh-context code review tools, and automated testing loops. Claiming that vendors "won't build verification subagents" is dangerous self-delusion—they already have, and will continue to improve them natively.

### The Real Problem for Engineering Leads
The core challenge for an **Engineering Lead** is not a lack of review tools, but **policy fragmentation and review throughput overload**:
* **Policy Fragmentation:** Team members use different vendors (Claude Code, Codex, Antigravity, Cursor). Vendor-shipped review tools only work inside their own walled garden and enforce generic vendor defaults.
* **Governance Overload:** As multi-vendor agent velocity increases, Tech Leads drown in PR reviews, risk rubber-stamping changes, and suffer architectural drift.

### Flywheel's Strategic Position: Repository-Resident Policy Sovereignty
Flywheel does not compete with vendor runtime tools; it governs them. **Flywheel is the repository's sovereign policy layer**, independent of whichever vendor harness or model executes the code.

```
+-----------------------------------------------------------------------------------+
|                        HETEROGENEOUS VENDOR HARNESSES                             |
|       (Claude Code / Codex / Antigravity / Cursor / CI Pipelines)                 |
+-----------------------------------------------------------------------------------+
                                          |
                                Governed & Audited by
                                          v
+-----------------------------------------------------------------------------------+
|          FLYWHEEL REPOSITORY-RESIDENT POLICY KERNEL (Vendor-Neutral)              |
|  * Repository Policy Sovereignty           * Cross-Vendor Policy Enforcement     |
|  * Anti-Fabrication Ledger (FACTS.md)      * Autonomy Dial & Merge Matrix (1-5)  |
|  * Self-Amending Friction Loop             * Local Cognitive Dashboard           |
+-----------------------------------------------------------------------------------+
```

---

## 2. Core Strategic Pillars

### Pillar 1: Policy Sovereignty vs. Vendor Execution
* **The Layer Distinction:** Vendor harnesses are *execution engines* (they run code, spawn agents, and execute reviews). Flywheel is the *repository's policy kernel* (it defines approval boundaries, anti-fabrication rules, and self-amending guidelines).
* **Vendor Neutrality:** Vendor review agents enforce generic platform defaults. Flywheel injects the repository's own specific rules, historical failure lessons ([LESSONS.md](/flywheel/LESSONS.md)), and verified facts ([FACTS.md](/flywheel/FACTS.md)) into any vendor's review process.

---

### Pillar 2: Opt-In Modular Core Skills & Trade-Off Matrix

Every internal Flywheel skill can be disabled or replaced based on the Engineering Lead's preferences:

| Core Skill | Native / Market Alternative | Trade-off of Opting Out (What you lose) | Trade-off of Opting Out (What you gain) | Recommended Strategy |
|---|---|---|---|---|
| **`delegate`** | Harness native subagents (`/agents`, Codex CLI subagents, Antigravity subagents) | Lose structured 5-tier role mapping and token-tracked JSON spawn ledgers (`spawns.json`). | Zero prompt context overhead; faster execution; native harness performance. | **OPT-IN / LEAN COLLAPSIBLE**<br>(Default to harness-native delegation; use `delegate` only when strict multi-model tiering is required). |
| **`wrapup`** | Native Auto-Memory (Claude Code / Antigravity memory) & standard `git commit` | Lose visual history sync to `dashboard.html` and auto-updating state ledgers (`activity.json`). | Eliminates session-end protocol overhead; frictionless developer velocity. | **MODULAR / DEGRADED MODE**<br>(Allow silent git commits without requiring full wrapup ledger updates). |
| **`improve`** | Static codebase instructions (`AGENTS.md`, `.cursorrules`) | Lose the self-amending friction loop (`IMPROVE.md`); project rules become static and stale over time. | Avoids rule bloat and context window degradation from accumulating markdown rules. | **KEEP AS UNIQUE MOAT**<br>(Retain self-amendment, but strictly enforce line budgets to prevent rule decay). |

---

### Pillar 3: Platform Absorption & Defensibility Analysis

| Feature / Capability | Absorption Risk | Defensibility Rationale | Strategic Action |
|---|:---:|---|---|
| **Subagent Spawning & Task Delegation** | **HIGH** | Vendors ship native subagent commands natively. | **UNBUNDLE:** Defer to native harness subagents. |
| **Basic Context Memory & Session Logs** | **HIGH** | Vendors ship auto-memory natively. | **DELEGATE:** Interoperate with native memory. |
| **Model Tier Routing (Sol/Terra/Luna)** | **HIGH** | Token costs drop; frontier models one-shot tasks. | **COLLAPSE:** Allow Solo/Lean modes. |
| **Fresh-Context Code Review** | **HIGH** | Vendors ship native review agents. | **GOVERN:** Guide vendor review agents via repo policy rather than building custom review runners. |
| **Repository Policy Sovereignty (`AUTONOMY.md`)** | **LOW** | Vendors build platform defaults; repos need custom, binding merge & risk rules. | **STRENGTHEN:** Focus on cross-vendor policy enforcement. |
| **Anti-Fabrication Truth Ledger (`FACTS.md`)** | **LOW** | Vendors generate plausible text; repos require verified fact dates and `Pending verification` states. | **STRENGTHEN:** Enforce truth verification across all skills. |
| **Self-Amending Friction Loop (`IMPROVE.md`)** | **LOW** | Vendors ship static guidelines; repos need rules that amend themselves from empirical failures. | **STRENGTHEN:** Protect the self-improvement loop. |
| **Local Visual Command Center (`dashboard.html`)** | **LOW** | Vendors build locked cloud SaaS or CLI text logs; leads need local offline visual synthesis. | **STRENGTHEN:** Single-file HTML cognitive dashboard. |

---

### Pillar 4: Extension Architecture Direction

Flywheel's extension model does not attempt to redefine how skills are written. Instead, it provides non-invasive policy wrapping:
* **Hook Boundaries:** Pre-execution and pre-merge validation via lightweight executable scripts ([check.sh](/flywheel/check.sh)).
* **Policy Declarations:** Third-party skills declare custom decision types into the autonomy matrix without modifying core framework code.
* **Zero Runtime Lock-in:** Third-party skills remain plain markdown (`SKILL.md`) or standard scripts, usable with or without Flywheel.

---

## 3. Qualitative Feature & Niche Prioritization

Features are ranked by strategic defensibility (Cross-Vendor Policy & Repo Sovereignty):

| Rank | Feature / Niche | Platform Absorption Risk | Strategic Direction & Commentary |
|:---:|---|:---:|---|
| **1** | **Repository Policy Sovereignty & Autonomy Dial** (`AUTONOMY.md`) | **LOW** | **STRENGTHEN:** Defines binding ask-vs-act rules for merges, schema forks, and side-effects across all vendor harnesses. |
| **2** | **Visual Cognitive Command Center** (`dashboard.html`) | **LOW** | **STRENGTHEN:** Single-file offline HTML turning multi-vendor PR reviews into high-bandwidth visual approvals (CTO/Lead view vs High-Level Product view). |
| **3** | **Anti-Fabrication Ledger & Truth Enforcement** (`FACTS.md`) | **LOW** | **STRENGTHEN & AUTOMATE:** Enforces `Pending verification` for environment values, API schemas, and CLI flags across all market tools. |
| **4** | **Self-Amending Friction Feedback Loop** (`IMPROVE.md`) | **MED** | **STRENGTHEN:** Amends repo rules session-by-session based on empirical friction (`LESSONS.md`), bound by line budgets to prevent rule bloat. |
| **5** | **Cross-Vendor Executable Hook Enforcers** (`check.sh`) | **MED** | **STRENGTHEN:** Deterministic pre-tool and pre-merge policy scripts that run identically regardless of the underlying harness. |
| **6** | **Third-Party Skill Policy Wrapper** | **LOW** | **DIRECTIONAL:** Non-invasive governance layer wrapping external skills inside Flywheel's safety guardrails without requiring skill edits. |
| **7** | **Cognitive SLA & Review Time Budgeting** | **LOW** | **DIRECTIONAL:** Caps PR context diff sizes and alerts when agent output exceeds acceptable human review time, protecting lead cognitive bandwidth. |
| **8** | **Multi-Harness Adapter Portability Layer** (`ADAPTERS.md`) | **HIGH** | **LEAVE AS-IS:** Maintains cross-vendor compatibility (Claude Code, Codex, Antigravity) with graceful degraded mode when subagents are unsupported. |
| **9** | **Role-Based Model Tier Hierarchy** (`ORCHESTRATION.md`) | **HIGH** | **UNBUNDLE / COLLAPSE:** 5-tier routing is prone to platform absorption. Make tiering collapsible to Solo/Lean modes. |
| **10** | **Session Wrapup Protocol & Manual Ledgers** (`wrapup.sh`) | **HIGH** | **OPT-IN / MODULAR:** Allow teams to substitute manual wrapup with platform-native auto-memory and standard git workflows. |

---

## 4. Deep-Dive: Core Moats & Qualitative Mechanics

### 1. Repository Policy Sovereignty (`AUTONOMY.md`)
* **Why it Wins:** Vendor tools execute code according to general platform defaults. A repository owned by an engineering team requires explicit, legally binding operational policies (e.g. "Schema refactors touching >10 files require explicit Lead approval at L3; dependency additions require L4").
* **Mechanism:** Flywheel maintains an explicit 1–5 autonomy dial stored in `flywheel/config.json`, enforcing decision gates across any harness.

### 2. Anti-Fabrication Truth Ledger (`FACTS.md`)
* **Why it Wins:** Vendor models and review agents routinely fabricate version numbers, CLI flags, and API endpoints. Vendor platforms have no incentive to highlight model unreliability.
* **Mechanism:** Maintains a date-stamped fact ledger. Any value recalled from memory or unverified live is flagged as `Pending verification`. Automated pre-commit hooks (`check.sh`) prevent unverified parameters from entering production configs.

### 3. Self-Amending Friction Feedback Loop (`IMPROVE.md`)
* **Why it Wins:** Vendor platforms do not retain project-specific failure history across different developer machines. Flywheel records empirical session failures in `LESSONS.md` and amends repo rules during `improve` passes.
* **Mechanism:** Governed by strict line and byte budgets (delete-to-add rule) to prevent context window bloat while ensuring rules compound over time.

---

## 5. Workflows for Engineering Leads

### Scenario 1: Governing Heterogeneous Vendor Teams
* **Context:** Developers on the team use different AI harnesses (e.g. Developer A uses Claude Code, Developer B uses Codex, CI runs GitHub Actions).
* **Flywheel Workflow:**
  1. Flywheel resides in the repo as the single source of truth for governance (`flywheel/`).
  2. Whichever harness executes a task, Flywheel's pre-commit/pre-merge hooks (`check.sh`) enforce identical autonomy rules, fact verifications, and branch checks.
  3. The Lead opens `dashboard.html` to review a single, unified visual summary of all agent activities across the codebase.

### Scenario 2: Incorporating Best-in-Class Ecosystem Skills
* **Context:** The team wants to use Matt Pocock's architecture skills, Superpowers TDD workflows, or GStack slash commands.
* **Flywheel Workflow:**
  1. Skills are added directly to `.agents/skills/`.
  2. Developers run third-party skills using their preferred harness.
  3. Flywheel wraps execution with repository policy: enforcing `FACTS.md` truth checks, logging decisions into `decisions.json`, and gating branch merges per `AUTONOMY.md`.

---

## 6. Implementation Roadmap & Strategic Direction

1. **Phase 1: Unbundle & Policy Sovereignty (Immediate)**
   - Add a configuration toggle in `flywheel/config.json` for `mode: "lean"` (solo coordinator + vendor-neutral policy).
   - Make `wrapup.sh` and 5-tier `delegate` skills optional.
   - **Immediate Impact:** Unbundling immediately allows Engineering Leads to use native vendor subagents and third-party skills without framework friction, while Flywheel's background policy hooks (`check.sh`) govern silently.

2. **Phase 2: Executable Policy Hooks & Visual Command Center (Core Governance)**
   - Migrate prose rules in `AUTONOMY.md` and `FACTS.md` into deterministic executable scripts ("Interfaces over prose").
   - Evolve `dashboard.html` into a dual-persona visual command center (Lead / CTO View vs High-Level Product View).
   - Track Cognitive SLA metrics (human review friction and diff complexity).

3. **Phase 3: Cross-Vendor Policy Standard & Plugin Scaling (Future)**
   - Defer formal plugin management harnesses until Lean Mode and core governance are mature.
   - Expand Flywheel as a open, repository-resident policy standard across emerging vendor harnesses.
