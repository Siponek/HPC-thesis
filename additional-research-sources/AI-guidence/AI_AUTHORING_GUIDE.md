# AI Authoring Guide for HPC Thesis

This file is the single reference for AI-assisted writing in this thesis project.
Use it before generating or editing any thesis chapter text.

## 1) Purpose
- Keep thesis content factually consistent with the implemented project.
- Prevent contradictory claims across chapters.
- Standardize scope, terminology, and evidence strength.

## 2) Canonical Project Positioning
- The artifact can be referred to as a game and can be categorized as a serious game in educational contexts.
- It is primarily intended for educational use (often instructor-guided), not pure standalone entertainment.
- Best use: introductory/icebreaker/reinforcement activity in HPC teaching.
- It complements lectures and exercises; it does not replace formal instruction.

## 3) Canonical Scope (Current)
- Core implemented concepts:
  - Sequential execution baseline (single-player mode).
  - OpenMP-style shared-memory analogy (multiplayer collaboration with shared container + private buffers).
- MPI:
  - Discussed in background/context.
  - Treat as future extension unless a chapter explicitly documents implemented MPI functionality with evidence.

## 4) Platform and Networking Consistency Rules
Use wording that matches implementation in the thesis source:
- Platform framing: web-first browser deployment.
- Networking framing: HTTP/SSE relay architecture used for browser compatibility.
- Do not claim pure peer-to-peer production architecture unless the chapter explicitly discusses it as conceptual/alternative.
- Do not mix conflicting statements such as "mobile-only" and "web-first" in the same section.

## 5) Claim Strength Rules
- Strong claims allowed only with evidence in current chapters/results.
- Use cautious phrasing for pedagogy outcomes:
  - Preferred: "preliminary evidence", "suggests", "indicates", "informal evaluation".
  - Avoid: "proves", "demonstrates definitive learning gains", "validated by controlled study" unless such study is documented.
- If no formal study is documented, explicitly state that limitation.

## 6) Terminology Standardization
Prefer these terms consistently:
- "educational tool" or "serious-game-based educational tool"
- "instructor-guided activity"
- "OpenMP shared-memory parallelism"
- "sequential vs parallel execution comparison"
- "private buffers (thread-local storage analogy)"
- "shared container (shared memory analogy)"

Avoid inconsistent wording:
- "full MPI implementation" (unless proven in implementation/results)
- "standalone game sufficient for learning without instruction"

## 7) Chapter Writing Directives
When generating text, enforce:

- 01-introduction.tex
  - State educational-tool framing early.
  - Mention classroom origin (physical card activity) and instructor role.
  - Keep research problem aligned to implemented scope.

- 02-background.tex
  - Keep MPI as context/future-work framing unless implementation evidence exists.
  - Link serious games to debrief/reflection practices.

- 03-methodology.tex
  - Describe instructional use model (activity + guided reflection).
  - Keep evaluation section honest about informal vs formal evidence.

- 04-architecture.tex / 05-implementation.tex
  - Focus on technical facts only.
  - Do not introduce new pedagogical claims without references/results.

- 07-results.tex / 08-conclusion.tex
  - Report preliminary educational value carefully.
  - Keep limitations explicit.
  - Separate confirmed technical outcomes from educational hypotheses.

## 8) Source Priority for AI Generation
When AI generates or revises text, prioritize sources in this order:
1. Current chapter .tex files in `chapters/`
2. `additional-research-sources/thesis-plan.md`
3. `additional-research-sources/thesis-draft.md`
4. `additional-research-sources/serious-game-hpc.pdf` for pedagogical framing

If sources conflict, prefer current implemented project state in `.tex` + documented results.

## 9) Required Pre-Write Check for AI
Before writing, AI should verify:
- Scope matches implemented features.
- No OpenMP/MPI contradiction.
- No web/mobile/network architecture contradiction.
- Claim strength matches evidence level.
- Terminology matches this guide.

## 10) Update Protocol
When project scope changes, update this file first, then revise chapters.
Always include date and summary under this section.

- 2026-02-19: Initial version created. Consolidated scope/positioning rules for consistent AI-assisted thesis writing.