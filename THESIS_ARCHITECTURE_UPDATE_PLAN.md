# Thesis Architecture Update Plan

## Overview

The thesis currently describes a **WebRTC-based P2P multiplayer** architecture, but the actual implementation uses **HTTP + SSE (Server-Sent Events)** through a signaling server relay. This document outlines all changes needed to align the thesis with the actual implementation.

## Key Architectural Difference

| Aspect | Thesis (Current) | Actual Implementation |
|--------|------------------|----------------------|
| Network Protocol | WebRTC P2P mesh | HTTP POST + SSE |
| Data Relay | Direct peer-to-peer | Server relay (star topology) |
| GDSync Usage | Native WebRTC transport | Custom shim layer |
| Platform Focus | Android-first, mobile | Web-first (browser) |
| Server Required | Only for signaling/handshake | Continuous relay server |

## Why This Change Was Necessary

**GDSync's WebRTC Transport Does NOT Work in Web Browsers:**
- Browsers are sandboxed - no direct UDP/ENet access
- No LAN peer discovery in browsers
- WebRTC in browsers requires STUN/TURN which adds complexity
- HTTP+SSE approach is simpler and more debuggable

This is a **significant technical contribution** that should be highlighted, not hidden.

---

## Chapter-by-Chapter Changes

### Chapter 1: Introduction (01-introduction.tex)

**Minor changes needed:**

1. **Line ~369 (Proposed Solution section)**:
   - Add mention of web platform as primary target
   - Mention the GDSync web patch as a technical innovation

2. **Contributions section**:
   - Add: "Development of a GDSync compatibility layer for web browsers using HTTP+SSE"

---

### Chapter 2: Background (02-background.tex)

**Changes needed:**

1. **Section 2.4 Multiplayer Game Architecture**:
   - Add subsection on **Server-Sent Events (SSE)** as an alternative to WebSockets
   - Add discussion of **HTTP-based game networking** patterns
   - Compare WebRTC vs HTTP relay approaches

2. **Add new subsection**: "Web Browser Networking Limitations"
   - Explain browser sandboxing
   - Discuss why traditional game networking doesn't work in browsers
   - Present HTTP+SSE as a solution

---

### Chapter 3: Methodology (03-methodology.tex)

**Significant changes needed:**

1. **Section 3.4.4 (WebRTC Selection) - REWRITE**:

   **BEFORE** (line ~404-436):
   ```
   WebRTC was chosen because:
   - Serverless Gameplay
   - NAT Traversal
   - Low Latency
   - Cross-Platform
   ```

   **AFTER**:
   ```
   ### Initial Approach: WebRTC
   WebRTC was initially chosen for:
   - Peer-to-peer connections
   - NAT traversal
   - Cross-platform support

   ### Web Platform Limitations
   However, testing revealed that GDSync's WebRTC transport
   did NOT function in web browsers due to:
   - Browser sandboxing preventing direct UDP access
   - No LAN peer discovery capability
   - Complex STUN/TURN configuration requirements

   ### Solution: HTTP + SSE Relay
   A custom signaling server with HTTP+SSE was implemented:
   - HTTP POST for sending game actions (fire-and-forget)
   - SSE for receiving real-time events (server push)
   - Star topology with server relay
   - Simpler debugging and deployment
   ```

2. **Section 3.3.3 (Supporting Plugins) - ADD**:
   - Mention the GDSync Web Patch as a custom development
   - Add signaling server as a required component

3. **Section 3.2.3 (Non-Functional Requirements) - UPDATE**:
   - **NFR4 Portability**: Change primary target from Android to Web
   - Keep Android as secondary/future target

---

### Chapter 4: Architecture (04-architecture.tex)

**MAJOR REWRITE NEEDED - This is the most affected chapter**

#### Section 4.1 System Layers (line ~36-46)

**CHANGE** Networking Layer description:

```latex
\item[Networking Layer] Manages connections via HTTP and Server-Sent Events,
state synchronization through a custom GDSync web patch layer, lobby system
for player matchmaking, and signaling server communication.
```

#### Section 4.2.3 Lobby Scene (line ~135-184)

**UPDATE** Connection Flow:

```latex
\paragraph*{Connection Flow:}
\begin{enumerate}
    \item Host starts signaling server on their machine
    \item Host creates room → receives unique room code from server
    \item Host shares room code with other players
    \item Other players connect to host's signaling server URL
    \item Players enter room code and join
    \item SSE connections established for real-time event streaming
    \item When all players ready, host initiates game scene transition
\end{enumerate}
```

**REMOVE** reference to "Direct peer-to-peer connections established"

#### Section 4.4 Multiplayer Architecture (line ~633+) - MAJOR REWRITE

**Section 4.4.1 Network Topology - REPLACE:**

```latex
\subsection{Network Topology}
\label{subsec:network-topology}

The game uses a \textbf{star network topology} with \textbf{server-relayed communication}
and \textbf{host-authoritative state management}.

\paragraph*{Topology Diagram:}

\begin{verbatim}
     ┌──────────────┐                        ┌──────────────┐
     │   Client A   │                        │   Client B   │
     │  (Browser)   │                        │  (Browser)   │
     │              │                        │              │
     │ GDSync Shim  │                        │ GDSync Shim  │
     └──────┬───────┘                        └──────┬───────┘
            │                                       │
            │  HTTP POST (send)                     │  HTTP POST (send)
            │  SSE stream (receive)                 │  SSE stream (receive)
            │                                       │
            ▼                                       ▼
     ┌─────────────────────────────────────────────────────┐
     │              Python Signaling Server                 │
     │                  (on Host machine)                   │
     │                                                      │
     │  - Relays game packets between clients               │
     │  - Manages lobby state (create/join/leave)           │
     │  - Pushes events via SSE to all connected clients    │
     └─────────────────────────────────────────────────────┘
\end{verbatim}

\paragraph*{Communication Characteristics:}
\begin{itemize}
    \item All game traffic relayed through signaling server
    \item HTTP POST requests for sending game actions
    \item Server-Sent Events (SSE) for receiving real-time updates
    \item Host runs signaling server; clients connect via HTTP
    \item Latency slightly higher than P2P but acceptable for this game type
\end{itemize}
```

**Section 4.4.3 GDSync Integration - REWRITE:**

```latex
\subsection{GDSync Web Patch Integration}
\label{subsec:gdsync-integration}

GDSync is a third-party multiplayer framework for Godot that normally uses
WebRTC for peer-to-peer communication. However, \textbf{GDSync's WebRTC
transport does not function in web browsers} due to browser sandboxing
and the inability to perform LAN peer discovery.

\paragraph*{The GDSync Web Patch:}

A custom compatibility layer was developed to enable GDSync functionality
in web browsers:

\begin{itemize}
    \item \textbf{Signal Interception}: Intercepts GDSync API calls
          (lobby\_create, lobby\_join, call\_func, etc.)
    \item \textbf{HTTP Transport}: Translates calls to HTTP POST requests
          to the signaling server
    \item \textbf{SSE Event Reception}: Listens for server-pushed events
          via SSE stream
    \item \textbf{Signal Emission}: Emits the same GDSync signals locally
          so existing game code works unchanged
\end{itemize}

\paragraph*{Architecture:}

\begin{lstlisting}[language=Python, caption={GDSync Web Patch architecture}]
# GDSync shim intercepts calls
GDSync.call_func(some_func, args)
    |
    v
LocalServerSignaling._process_host_broadcast_requests()
    |
    v
SignalingClient.broadcast_packet(base64_encoded_data)
    |
    v
HTTP POST /api/lobby/broadcast
    |
    v
Signaling Server relays to target clients via SSE
    |
    v
Client receives SSE event: game_packet
    |
    v
LocalServerSignaling processes packet
    |
    v
Emits appropriate GDSync signals locally
\end{lstlisting}

\paragraph*{Key Files:}
\begin{itemize}
    \item \texttt{scenes/Multiplayer/GDSyncWebPatch/signaling\_client.gd}:
          HTTP + SSE client
    \item \texttt{scenes/Multiplayer/GDSyncWebPatch/local\_server\_signaling.gd}:
          GDSync signal shim
    \item \texttt{signaling-server/server.py}: Python signaling server
\end{itemize}
```

#### Section 4.6 Data Flow Diagrams - UPDATE

Update the multiplayer data flow diagrams to show HTTP+SSE instead of WebRTC RPC.

---

### Chapter 5: Implementation (05-implementation.tex)

**Changes needed:**

1. **Section 5.1 Project Structure - UPDATE**:
   - Add `signaling-server/` directory
   - Add `GDSyncWebPatch/` subdirectory

2. **Section 5.4 Multiplayer Mode Implementation - REWRITE**:
   - Remove WebRTC handshake description
   - Add HTTP+SSE connection flow
   - Add signaling server setup instructions

3. **ADD NEW SECTION: "GDSync Web Patch Implementation"**:
   - Describe the shim layer architecture
   - Show key code from `local_server_signaling.gd`
   - Explain signal interception and emission pattern

4. **ADD NEW SECTION: "Signaling Server Implementation"**:
   - Python aiohttp server structure
   - HTTP API endpoints
   - SSE event streaming
   - Lobby state management

---

### Chapter 6: Problems (06-problems.tex)

**Changes needed:**

1. **Section 6.2 GDSync Framework Challenges - EXPAND**:
   - **ADD** subsection: "Web Platform Incompatibility"
   - Explain WHY GDSync WebRTC doesn't work in browsers
   - Describe the solution (custom shim layer)

2. **ADD NEW SECTION: "Web Browser Limitations"**:
   - Browser sandboxing challenges
   - No UDP access
   - No LAN discovery
   - Solution: HTTP+SSE relay

3. **Section 6.5 Multiplayer Synchronization - UPDATE**:
   - Note that HTTP adds latency compared to P2P
   - Discuss trade-off: simplicity vs latency

---

### Chapter 7: Results (07-results.tex)

**Changes needed:**

1. **Section 7.3.2 Network Performance - UPDATE**:
   - Note that measurements are for HTTP+SSE, not P2P WebRTC
   - Explain that latency includes server relay hop

2. **Section 7.4 Platform Compatibility - UPDATE**:
   - Primary platform: Web browsers (Chrome, Firefox, Edge)
   - Secondary platform: Android (via native export)
   - Note: Desktop also works

---

### Chapter 8: Conclusion (08-conclusion.tex)

**Changes needed:**

1. **Section 8.1 Summary of Contributions - ADD**:
   - "Development of GDSync web compatibility layer enabling browser-based multiplayer"

2. **Section 8.4 Future Work - ADD**:
   - "Optimize HTTP+SSE latency or implement WebSocket alternative"
   - "Investigate WebRTC direct connection for lower latency"

---

## New Content to Add

### New Architecture Diagram (for figures/)

Create a proper diagram showing:
```
┌──────────────┐     HTTP POST      ┌─────────────────┐     HTTP POST      ┌──────────────┐
│   Client A   │ ─────────────────→ │    Signaling    │ ←───────────────── │   Client B   │
│  (Browser)   │ ←───────────────── │     Server      │ ─────────────────→ │  (Browser)   │
└──────────────┘     SSE stream     │  (Python/aio)   │     SSE stream     └──────────────┘
                                    └─────────────────┘
```

### New Code Listings to Add

1. `SignalingClient.broadcast_packet()` - HTTP POST sending
2. `_handle_sse_event()` - SSE event processing
3. `_process_host()` - Game packet processing
4. Python server `send_to_peer()` - SSE broadcast

---

## Files to Update

### High Priority (Must Change)

| File | Changes |
|------|---------|
| `03-methodology.tex` | Rewrite WebRTC section, add HTTP+SSE rationale |
| `04-architecture.tex` | Major rewrite of multiplayer architecture |
| `05-implementation.tex` | Add GDSync patch implementation details |
| `06-problems.tex` | Add web browser limitation section |

### Medium Priority (Should Change)

| File | Changes |
|------|---------|
| `01-introduction.tex` | Update contributions list |
| `02-background.tex` | Add SSE background |
| `07-results.tex` | Update network metrics context |
| `08-conclusion.tex` | Update contributions and future work |

### Low Priority (Nice to Have)

| File | Changes |
|------|---------|
| Abstract | Update technology mentions |
| Appendices | Add signaling server API reference |

---

## Addressing THESIS_REVIEW_ISSUES.md Items

### CRITICAL #1: Visual Content (Screenshots)

**User will provide screenshots. Needed screenshots:**

1. Main menu interface
2. Single-player game showing cards, buffers, timer
3. Multiplayer lobby (create room, join room)
4. Multiplayer gameplay (multiple players view)
5. Victory/completion screen
6. **NEW: Signaling server console output**
7. **NEW: Browser developer tools showing SSE stream**

### CRITICAL #2: Missing Chapters

Chapters 5 and 6 exist and are relatively complete. Main gap is the architectural changes needed.

### CRITICAL #3: Educational Effectiveness Claims

This is unchanged by the architecture update. Still needs to be addressed separately by reframing claims.

---

## Summary of Key Narrative Changes

### Before (WebRTC P2P):
> "The game uses peer-to-peer WebRTC connections for low-latency multiplayer gameplay, with a signaling server only for initial connection establishment."

### After (HTTP+SSE Relay):
> "The game uses an HTTP + SSE relay architecture through a signaling server. This approach was necessitated by web browser limitations: GDSync's native WebRTC transport does not function in browsers due to sandboxing and lack of LAN peer discovery. The custom GDSync Web Patch intercepts GDSync API calls and translates them to HTTP requests, enabling the same game code to work across platforms."

### Technical Contribution Highlight:
> "A significant technical contribution of this work is the GDSync Web Patch - a compatibility layer that enables GDSync-based multiplayer games to function in web browsers using HTTP+SSE instead of WebRTC. This pattern is reusable for other Godot-based educational games targeting web deployment."

---

## Estimated Work

| Task | Time Estimate |
|------|---------------|
| Update Chapter 3 (Methodology) | 2-3 hours |
| Rewrite Chapter 4 (Architecture) | 4-6 hours |
| Update Chapter 5 (Implementation) | 3-4 hours |
| Update Chapter 6 (Problems) | 2-3 hours |
| Minor updates to other chapters | 2-3 hours |
| Create new diagrams | 2-3 hours |
| Add screenshots (when provided) | 1-2 hours |
| **Total** | **16-24 hours** |
