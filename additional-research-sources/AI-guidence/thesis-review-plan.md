# Thesis Review Plan: HPC Sorting Serious Game — Tough Love Edition

**Date:** 2026-02-20  
**Status:** DRAFT — Approved for execution

---

## TL;DR

The implementation chapter (Ch.5) is 156 lines — the shortest chapter and dangerously thin for a master's thesis. The appendices contain fabricated project structures, Android-specific instructions (contradicting the web-first framing), and API docs for classes that don't exist. 23+ TODO artifact groups remain unresolved. The barrier synchronization system — one of the most pedagogically impressive features — is completely absent from the thesis.

---

## Priority 1: CRITICAL (Must Fix Before Submission)

### Step 1: Expand Chapter 5 (Implementation) with real code

Currently 156 lines with 3 pseudocode snippets. Should include:

- **CardState transport protocol** from `scenes/Multiplayer/MultiplayerGame/multiplayer_card_manager.gd` (lines 6-49) — inner class showing serialization for network sync
- **BarrierManager state machine** from `scenes/Multiplayer/MultiplayerGame/barrier_manager.gd` (113 lines) — implements actual HPC barrier synchronization concept. Currently **completely absent** from thesis
- **multiplayer_card_manager._ready()** initialization showing host/client divergence (`multiplayer_card_manager.gd` lines ~75-100)
- **Real gdsync_web_patch.gd** code (67 lines) — already interesting and directly relevant to Ch.6 web-patch case study
- **connection_manager.gd** signal architecture (GDSync signal wiring pattern, lines ~40-55)
- **Real sorting validation** — replace pseudocode with actual `card_manager.gd` implementation
- **Real visibility control** — replace pseudocode with actual code from `multiplayer_card_manager.gd`
- Add a **new section on Barrier Synchronization** as a pedagogical feature (BarrierManager + BarrierControlPanel + BarrierLockOverlay)

Target: expand Ch.5 from 156 lines to ~400-500 lines.

### Step 2: Rewrite Appendix A (User Manual) for web deployment

Current content describes APK installation, Android 7.0, Google Play, 5-inch screens, OpenGL ES 3.0.

Replace with:
- Browser requirements (modern browser with WebAssembly support)
- URL-based access (no installation)
- Touch/mouse input on browser
- Responsive layout behavior
- Signaling server requirements for multiplayer

### Step 3: Fix Appendix B (Code Listings) project structure

Current structure is fabricated (`scripts/card.gd`, `scripts/networking/http_transport.gd`, etc.).

Replace with actual structure:
```
scenes/CardScene/scripts/card_manager.gd
scenes/CardScene/scripts/card.gd
scenes/CardScene/scripts/card_buffer.gd
scenes/Multiplayer/connection_manager.gd
scenes/Multiplayer/multiplayer_types.gd
scenes/Multiplayer/MultiplayerGame/multiplayer_card_manager.gd
scenes/Multiplayer/MultiplayerGame/barrier_manager.gd
scenes/Multiplayer/Lobby/multiplayer_lobby.gd
scenes/Multiplayer/GDSyncWebPatch/gdsync_web_patch.gd
scenes/Multiplayer/GDSyncWebPatch/signaling_client.gd
scenes/Multiplayer/GDSyncWebPatch/local_server_signaling.gd
signaling-server/server.py
```

### Step 4: Fix or gut Appendix C (API Documentation)

Remove fabricated classes: `Buffer`, `NetworkSync`, `GameMode`, `EventBus`, `Profiler`, `Config`.
Remove hypothetical debug console commands.
Document only what actually exists (Card, CardManager, MultiplayerCardManager, BarrierManager, ConnectionManager).

### Step 5: Fix Appendix D (Study Materials)

- Fix discussion question: "How does single-player mode relate to shared-memory parallel programming?" → single-player is the **sequential** baseline, not shared-memory
- Resolve target audience inconsistency: exercises say "aged 12-16" but rubric asks for OpenMP code implementation
- Remove MPI mapping table (already done per comment, verify)

### Step 6: Remove placeholder text

- `08-conclusion.tex` line ~473: `\[To be written last, after all revisions are complete.\]` — renders as visible math in PDF
- `references.bib` line 245: `https://github.com/your-username/hpc-sorting-serious-game` → `https://github.com/Siponek/hpc-sorting-serious-game`

### Step 7: Fix platform framing consistency

Replace Android/smartphone/APK/mobile references throughout with web-first/browser language:
- Ch.6 "Mobile UI/UX Challenges" → "Responsive UI/UX Challenges" or "Small-Screen/Touch UI Challenges"
- Ch.8 "leveraging the ubiquity of smartphones" → "leveraging web browser accessibility"
- Ch.8 "Mobile Constraints Are Real" → "Viewport/Touch Constraints Are Real"

---

## Priority 2: HIGH (Should Fix)

### Step 8: Add BarrierManager to Architecture chapter (Ch.4)

Add a section in Ch.4 documenting the barrier synchronization architecture:
- `BarrierManager` state machine (RUNNING → WAITING_AT_BARRIER → BARRIER_ACTIVE)
- `BarrierControlPanel` UI component
- `BarrierLockOverlay` interaction blocking
- How this maps to `#pragma omp barrier`

### Step 9: Create critical missing diagrams

At minimum:
- Scene-transition/state diagram (MainMenu → SinglePlayer/Lobby → MultiplayerGame → Completion)
- Component hierarchy diagram (CardManager → MultiplayerCardManager inheritance)
- Web patch before/after architecture diff

### Step 10: Rebalance chapter lengths

- Consider trimming Ch.3 (Methodology, 707 lines) — technology selection tables may be overly detailed
- Expand Ch.4 (Architecture, 259 lines) with real diagrams and barrier sync section
- Expand Ch.5 (Implementation, 156 lines) as described in Step 1

### Step 11: Remove unverified quote

`"The best way to learn is by doing." — Ancient Proverb` in Final Thoughts. Either find proper attribution or remove.

---

## Priority 3: MEDIUM (Nice to Have)

### Step 12: Add screenshots/figures

- Screenshot montage of game UI (main menu, singleplayer, multiplayer, lobby, buffers, completion)
- Performance charts if data exists
- VarTree debug panel screenshot (already referenced, exists)

### Step 13: Resolve LaTeX issues

- Rebuild with biber to clear `papastergiou2009digital` citation warning (entry exists in .bib)
- Verify `\label{app:c}` placement in Appendix C
- Confirm only correct examiner name is active in `main.tex`

### Step 14: Address remaining TODO artifacts

23+ TODO groups across chapters. Prioritize by impact — diagrams and real code excerpts first, nice-to-have figures last.

---

## Verification

After all changes:
1. Compile LaTeX end-to-end: `latexmk -pdf main.tex`
2. Search for remaining `TODO` markers: `grep -rn "TODO" chapters/ appendices/`
3. Search for placeholder text: `grep -rn "your-username\|To be written\|placeholder" .`
4. Verify all `\ref{}` and `\cite{}` resolve without warnings
5. Check page count balance between chapters
6. Read PDF cover-to-cover for narrative consistency

---

## Decisions

- **Platform framing**: web-first (not mobile-first, not Android)
- **Appendix strategy**: fix to match reality rather than remove entirely
- **Implementation chapter scope**: show real code with analysis, not exhaustive listings
- **Barrier sync**: must be added — it's a key pedagogical feature hidden from the thesis
