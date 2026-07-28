# Flywheel Positioning, Human-Bottleneck & Cognitive Dashboard (2026-07-26)

> **"Models will get faster; harnesses will get smarter. Human cognitive bandwidth is fixed."**

This document captures the strategic synthesis, competitive analysis, and open questions from the July 2026 exploration session on Flywheel's positioning, human cognitive affordability, CEO/CTO dashboard visualization, and skill design lessons from Matt Pocock's `skills` framework.

---

## 1. Executive Summary: The Human Bottleneck Thesis

As AI models advance in speed, context length, and multi-step execution capability, the primary bottleneck in agent-driven software development has shifted: **it is no longer code generation speed, but human comprehension and verification throughput.**

When agent velocity exceeds human cognitive bandwidth, teams suffer two major failure modes:
1. **Review Stagnation:** PRs and branches accumulate because digesting multi-file refactors takes too much manual effort.
2. **Rubber-Stamping ("Unconscious Approval"):** Humans approve agent outputs without deep review, introducing hidden contract breaks, architectural drift, and technical debt.

Flywheel's ultimate value proposition is **Governance, Transparency, and Cognitive Affordability**. It turns multi-agent development into a trustworthy, predictable investment by minimizing the cognitive effort needed for a human operator to grasp a situation and make decisions.

---

## 2. Competitive Landscape & Platform Absorption Reality

### Market Survey (July 2026)

| Project / Framework | Approach & Focus | Strengths | Vulnerability |
|---|---|---|---|
| **Superpowers** | SDLC skill packs (TDD, spec-first, brainstorming) | Disciplined workflows, easy adoption | No session persistence or verification gates |
| **GStack (Garry Tan)** | Role-playing personas (CEO, EM, QA, Security) | Simple slash commands, founder focus | Persona flavor text; lacks adversarial verification |
| **Hermes Agent (Nous)** | Always-on, self-learning AI OS | Persistent memory, autonomous learning | Hard to inspect state; high complexity |
| **BMAD-METHOD** | Full SDLC org-chart roles & markdown specs | High structure, broad role coverage | Heavy prompt overhead; static methodology |

### The Platform Absorption Reality
Basic orchestration, subagent delegation, skill definition, and memory storage will inevitably be absorbed natively by harnesses (Claude Code, Codex, Antigravity) or frontier models themselves. 

**Flywheel's Non-Absorbable Moat:**
1. **Cross-Vendor Portability:** Repository-resident policy bound to no single vendor ecosystem.
2. **Anti-Fabrication Ledger (`FACTS.md`):** First-class `Pending verification` states and source-dated fact validation.
3. **Adversarial Fresh-Context Verification (HR3):** Strict policy that no agent self-verifies its output.
4. **Self-Amending Friction Loop (`IMPROVE.md`):** Rules that amend themselves session-by-session based on empirical friction.
5. **Visual Cognitive Command Center (`dashboard.html`):** High-bandwidth local visual synthesis for the human operator.

---

## 3. Dual-Persona Visual Command Center (`dashboard.html`)

To reduce human verification time from 15 minutes to 15 seconds, `dashboard.html` evolves into a dual-mode visual command center.

### CEO Mode (Vibe-Coding / High-Level Product View)
* **Goal:** Maximum velocity, visual progress, minimum jargon.
* **Key Visuals:**
  * 1-Click Decision Cards (Pending merge gates, explicit recommendations).
  * Milestone & Feature Progress Bars (`done/total`).
  * Before/After Visual Delta Summaries (Screenshot/UI diffs or human-readable impact scope).
  * Risk Traffic Light (🟢 Low Risk / 🟡 Medium Risk / 🔴 Structural Risk).

### CTO Mode (Architectural Transparency & Debt Audit)
* **Goal:** Complete architectural visibility, technical debt tracking, and decision lineage.
* **Key Visuals:**
  * **Interactive Topology Graph:** Component relationships, dependency boundaries, and state mutations (powered by Mermaid / SVG).
  * **Git Hotspot Heatmap:** High-churn modules touched across recent sessions.
  * **Agent Lineage Tree:** Visualization of subagent delegations ($\text{Coordinator} \rightarrow \text{Architect} \rightarrow \text{Engineer} \rightarrow \text{Verifier}$) with token costs and outcome statuses.
  * **Fresh-Context Verifier Audit Log:** Detailed pass/fail test traces and rule compliance metrics.

---

## 4. Synthesis of Lessons from Matt Pocock's `skills` Repo

Insights from analyzing [`mattpocock/skills`](https://github.com/mattpocock/skills):

### A. Skill Design & Context Hygiene (`writing-great-skills`)
* **Predictability over Output Identity:** The root virtue of a skill is forcing a deterministic *process*, not identical outputs.
* **Model-Invoked vs. User-Invoked Trade-off:**
  * Model-invoked skills pay **Context Load** (descriptions sit in prompt window every turn).
  * User-invoked skills (`disable-model-invocation: true`) pay zero context load, but require human **Cognitive Load**.
  * Use **Router Skills** when user-invoked commands multiply past human memory.
* **Information Hierarchy:**
  * Tier 1: In-skill steps with **Exhaustive & Checkable Completion Criteria** (prevents premature completion).
  * Tier 2: In-skill reference (flat peer-set rules).
  * Tier 3: Context pointers to external files (`GLOSSARY.md`, ADRs) loaded only when needed.

### B. Architectural Vocabulary (`improve-codebase-architecture`)
* **Scope Before Scan (YAGNI):** Analyze `git log --oneline` hotspots or focus on human-directed modules rather than scanning 100% of the repo.
* **Module Depth Vocabulary:** Classify modules as *deep* (simple interface, complex implementation) vs. *shallow* (interface as complex as implementation).
* **The Deletion Test:** *"If I delete this module, does it concentrate complexity elsewhere or just move it around?"*
* **Metrics for CTO View:** Incorporate **Locality**, **Seam Friction**, and **Module Depth** into Flywheel's topology reports.

### C. Domain Vocabulary (`CONTEXT.md`)
* Introduce lightweight project glossaries so agents speak domain jargon immediately (e.g., *"materialization cascade"* instead of 20-word descriptions), saving tokens and reducing verbosity.

---

## 5. Unresolved Questions & Open Strategic Dilemmas

The following open questions remain to be answered in future research sessions:

### Q1: The Framework Flexibility Friction
* *Dilemma:* Matt Pocock's skills are completely unbundled, self-contained utilities run ad-hoc. Flywheel is a stateful, structured framework (`check.sh`, `STATUS.md`, 5 JSON ledgers).
* *Open Question:* How can Flywheel support **ad-hoc utility execution** (e.g., running a 2-minute visual architecture scan or fresh verifier check mid-session) without breaking or forcing a full session wrapup protocol?

### Q2: The "Marking Its Own Homework" Debt Problem
* *Dilemma:* If the engineering agent generates the code *and* writes the technical debt summary, it will naturally under-report its own antipatterns or shallow modules.
* *Open Question:* Can we enforce that all architectural depth scores and technical debt items in `dashboard.html` are generated strictly by an **adversarial, fresh-context verifier/auditor subagent** (HR3)?

### Q3: Quantifying the Cognitive SLA
* *Dilemma:* "Reducing cognitive load" is a qualitative claim. Without a concrete metric, we cannot verify if Flywheel is succeeding.
* *Open Question:* What is Flywheel's measurable Cognitive SLA? (e.g., *"Can a human make a safe level-3 merge decision in under 30 seconds using only the dashboard summary?"*)

### Q4: Persona Switching UX in Single-File HTML
* *Dilemma:* How do we implement CEO vs. CTO view modes in a zero-dependency, single offline `dashboard.html` file without visual clutter or breaking template performance?
* *Open Question:* Should CEO/CTO modes be a simple top-level toggle in `template.html`, or should they persist per-user state in `localStorage`?

---

*Document compiled from exploration session on 2026-07-26. Supersedes/complements `strategy-2026-07.md`.*
