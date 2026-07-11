# Agentic Frameworks and Methodologies: Six-Way Comparative Analysis (2026-07-11)

This research document compares the **Flywheel** framework with five other major agentic development frameworks and methodologies: **GStack**, **BMAD**, **GSD**, **Spec Kit**, and **OpenSpec**.

---

## 1. Executive Summary

Modern AI-driven coding agents require structures to move beyond unstructured "vibe coding". The leading frameworks handle this through distinct strategies:
*   **Flywheel**: Focuses on **governance, risk control, and self-amending policy rules** to guarantee repository integrity and anti-fabrication correctness.
*   **GStack**: Focuses on **velocity and interactive developer tools** to turn single-developer sessions into a multi-persona virtual startup team with browser QA.
*   **BMAD**: Focuses on **Agile processes and specification sharding** to force a structured planning and execution lifecycle.
*   **GSD**: Focuses on **context engineering and git automation** to combat context rot through fresh-run task executions.
*   **Spec Kit**: Focuses on **immutable tenets and spec hierarchy**, anchoring all agent runs with a project Constitution.
*   **OpenSpec**: Focuses on **simplicity and brownfield legacy support** with a lightweight 3-stage (Propose → Apply → Archive) workflow.

---

## 2. Comparison Matrix

| Dimension | Flywheel | GStack | BMAD Method | GSD (Open GSD) | Spec Kit | OpenSpec |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Motto / Core Metaphor** | *"Heroes come and go; policies compound."* | *"A virtual engineering team at your fingertips."* | *"Ditch vibe coding for disciplined spec-driven agile."* | *"Solve context rot with atomic milestones and fresh runs."* | *"Specs as the compiler-like source of truth."* | *"Propose, Apply, Archive — brownfield-first spec workflow."* |
| **Primary Goal** | Repository governance, anti-fabrication discipline, and self-amending operating policy. | Solo developer velocity, interactive startup roles, and automated browser QA. | Agile product development lifecycles, structured planning, and spec sharding. | Preventing agent context rot, milestone slicing, and Git automation. | Clear specification hierarchy, metadata standards, and project grounding. | Lightweight, low-overhead spec-driven development for legacy systems. |
| **Architectural Layer** | **Operating Policy & Audit Log** (runs on top of subagent harnesses). | **Custom Harness Skills & Toolset** (extends the execution engine). | **Agile Methodology & Workflow** (directs execution phases). | **Context Engineering & Git Harness** (manages execution environments). | **Spec Pipeline & Context Grounding** (sets repository metadata). | **Document State Machine** (Propose → Apply → Archive). |
| **Context Strategy** | Fresh-context verifiers, strict always-loaded prompt size budget. | Session memory, `CLAUDE.md`, and manual `/context-save`. | Document sharding (splitting PRD/architecture into Epic/Story cards). | Task-level sharding; each task runs in a fresh, isolated agent thread. | Immutable repository Constitution + structured template schema files. | Active-context isolation; active specs are archived immediately on completion. |
| **Host/Adapter Dependency** | **Adapter-Neutral** (supports Claude Code, Codex, OpenCode, Antigravity). | **Claude Code-First** (designed around slash commands, uses Bun/Playwright). | **Tool-Agnostic** (designed for Cursor, Claude Code, Copilot, etc.). | **Harness CLI-First** (`gsd-pi` runner with `gsd-core` plugins). | **Tool-Agnostic** (generates files readable by any major agent). | **Tool-Agnostic** (works across Claude Code, Cursor, Windsurf, etc.). |
| **Directory Presence** | Repo-resident `flywheel/` folder with Markdown rules and JSON logs. | Local `~/.codex/skills/` configurations and project-level `CLAUDE.md`. | Hidden `_bmad/` configs and `_bmad-output/` planning artifacts. | Local configuration files and task state metadata tracking. | Project `specify/` templates and directory structure definitions. | Folder structures (e.g., `specs/active/`, `specs/archived/`). |
| **Verification Strategy** | **HR3 Policy**: Builder never self-verifies; fresh-context verifier required. | **Automated Headless QA**: Runs Playwright tests via Chromium daemon. | **Agile QA**: Verifies implementation strictly against sharded story specs. | **Fresh-Run verification**: Dedicated check step runs in isolated context. | **Spec-alignment check**: Validates code against specified criteria. | **Validation check**: Developer review + automated tests during Apply. |
| **Rule Evolution** | **Self-Amending Improve Loop** (IMPROVE.md, friction ledger). | Static prompt templates and developer-managed local conventions. | Static workflow methodology. | Static task/milestone loop. | Static templates and immutable Constitution. | Static methodology (can load custom plugins via OpenSpec Plus). |
| **Developer UX** | Silent hooks, CLI checker (`check.sh`), offline HTML dashboard. | Rich interactive slash commands in the CLI console (e.g., `/qa`, `/retro`). | Pre-defined folder structure and artifact-oriented workflow stages. | CLI milestone management, git worktree checkouts, atomic commits. | `specify` CLI commands, structured Markdown templates. | Low-overhead CLI prefix (e.g., `/opsx propose`, `apply`, `archive`). |

---

## 3. Core Philosophical Differences

### The Execution Strategy
*   **Flywheel (Governance)**: Focuses on risk reduction. It models the AI as an untrustworthy runner that requires strict execution tiers, an autonomy matrix, anti-fabrication guidelines, and independent auditing.
*   **GStack (DX / Velocity)**: Focuses on capabilities and solo builder leverage. It provides role simulation and deep automated browser testing integration (via Playwright) to test and ship web apps fast.
*   **BMAD (Sprint Process)**: Focuses on Agile methodology. It emulates software sprint steps, organizing planning and code generation gates.
*   **GSD (Context Engineering)**: Focuses on context boundaries. It splits tasks into fresh agent executions combined with git worktree automation to eliminate context degradation.
*   **Spec Kit (Tenets)**: Focuses on repository standards. It establishes an immutable repository Constitution, grounding all agent runs.
*   **OpenSpec (Simplicity)**: Focuses on minimalist, brownfield-friendly workflows. It requires a Proposal document that is archived once Applied.

---

## 4. Unique Framework Strengths

### What Flywheel Offers
1.  **Self-Amending Improve Loop (`IMPROVE.md`)**: Automatically rewrites repository policy rules based on session-by-session friction logs.
2.  **Anti-Fabrication Fact Discipline (`FACTS.md`)**: Mandates that external parameters/libraries are doc-sourced, preventing LLM guesswork.
3.  **Explicit Autonomy Dial (`AUTONOMY.md`)**: A clear contract mapping what the AI can do versus what requires human approval.
4.  **CEO Audit Dashboard (`dashboard.html`)**: Logs all agent costs, decisions, and spawns into structured JSON ledgers.
5.  **HR3 Verification Policy**: Strict adversarial verification where the building agent cannot grade its own work.

### What GStack Offers
1.  **Headless Browser Integration (`/qa` / `/browse`)**: Launches a persistent Chromium daemon via Playwright for visual frontend testing.
2.  **Session Cookie Injection (`/setup-browser-cookies`)**: Imports browser cookies to test authenticated user flows.
3.  **Developer Slash Commands**: Custom CLI shortcuts like `/office-hours` (YC critique) or `/retro`.
4.  **20+ Specialized Startup Roles**: Simulates a complete startup org chart (Security, Design, EM, CEO).

### What BMAD Offers
1.  **Spec Sharding**: Breaks large PRD/Architecture files into focused Epic/Story files to avoid context bloat.
2.  **Agile Phase Gates**: Moves the project strictly from Planning (Phase 1) to Execution (Phase 2).
3.  **Scale-Adaptive Planning**: Automatically scales planning depth based on task size.

### What GSD Offers
1.  **Strict Task-Level Spawning**: Launches a fresh agent container for every task to completely eliminate context rot.
2.  **Worktree-Aware Git Automation**: Automatically manages git worktrees for isolated task execution.
3.  **Atomic Git Commit Hygiene**: Enforces a strict commit-on-success pipeline for clean project histories.

### What Spec Kit Offers
1.  **Immutable Project Constitution**: Sets core tenets (e.g., coding principles, library constraints) that agents cannot violate.
2.  **Specify-Plan-Implement Pipeline**: A standardized, compiler-like specification pipeline.
3.  **High Multi-Agent Compatibility**: Runs natively across Cursor, Claude Code, Gemini CLI, etc.

### What OpenSpec Offers
1.  **Brownfield-First Design**: Extremely simple to adopt in existing legacy projects without establishing complex setups.
2.  **Propose-Apply-Archive Lifecycle**: A minimal 3-step state machine that provides durable context without overhead.
3.  **Extensible OpenSpec Plus Skills**: Optional plugins for discovery, architecture critique, and release notes.

---

## 5. Strategic Recommendations

*   **Choose Flywheel for:** High-stakes, long-living systems where safety, strict governance, auditability, and self-improving repository standards are paramount. Excellent for multi-developer/multi-session environments.
*   **Choose GStack for:** Solo founders and developers building interactive full-stack web applications who want high velocity and visual/functional browser-testing tools.
*   **Choose BMAD for:** Teams looking to transition from ad-hoc prompting to structured, spec-driven Agile software development lifecycles, ensuring a solid PRD and architecture exist before code is written.
*   **Choose GSD for:** Projects suffering from agent degradation, context bloating, and messy git histories on long-running tasks.
*   **Choose Spec Kit for:** Projects seeking tool-agnostic standards for Specification-Driven Development grounded by a core repository Constitution.
*   **Choose OpenSpec for:** Developers who want a lightweight, low-overhead Spec-Driven Development workflow for legacy codebases with minimal barrier to entry.
