# AW AFK Parasite HPR Extension

This extension leeches off the official ActivityWatch AFK watcher (aw-watcher-afk). It acts as a lightweight server inside HPR, intercepts AFK heartbeats, and automatically pauses/resumes HPR tracking based on whether you are active at your computer.

It does NOT require the actual ActivityWatch desktop application. HPR mimics the ActivityWatch server, allowing aw-watcher-afk to control HPR tracking with a near-zero memory footprint.

---

## Description

The AW AFK Parasite HPR Extension is a lightweight module that monitors your keyboard and mouse activity via aw-watcher-afk. Instead of running the full ActivityWatch desktop suite, this extension operates as a local receiver. It hooks directly into the telemetry sent by aw-watcher-afk.

aw-watcher-afk sends periodic heartbeats to a local web server on port 5600 containing a status field: `afk`, `not-afk`, or `hibernating`. HPR starts a fake server on this exact port, reads the incoming status, and calls `HPR.stopTracking_E` when you go AFK or hibernate, and `HPR.startTracking_E` when you return.

---

## Installation

### 1. Install the Lua Extension Script
Place the `AW-AFK-Parasite-HPR-Extension.lua` script inside HPR's extension directory:

* **On Windows**: `%APPDATA%\HPR\HPR_Config\extensions\AW-AFK-Parasite-HPR-Extension.lua`
* **On Linux**: `~/.config/HPR/extensions/AW-AFK-Parasite-HPR-Extension.lua`

### 2. Install aw-watcher-afk
Download and install aw-watcher-afk from the official ActivityWatch releases. You do NOT need to install or run the full ActivityWatch suite — only the standalone watcher binary is needed.

### 3. Make sure Activtywatch is not running

Make sure the real ActivityWatch desktop application is **not** running, otherwise it will occupy port 5600 before HPR can.

---

## Technical Specifications

1. **Port (5600)**: The default port used by all ActivityWatch watchers. HPR listens exclusively on `127.0.0.1:5600`.
2. **CORS Options**: The server automatically responds to `OPTIONS` preflight requests to satisfy the watcher client.
3. **Bucket Validation**: When aw-watcher-afk registers its bucket on startup, HPR echoes back a mocked bucket configuration to satisfy the client's validation checks.
4. **AFK Status Values**: The extension handles all three possible status values sent by aw-watcher-afk:
   - `not-afk` — you are active, tracking resumes
   - `afk` — no keyboard/mouse activity detected, tracking pauses
   - `hibernating` — machine woke from sleep, treated the same as afk until activity resumes

---

## Known Limitations

### 1. Port Binding Conflicts
The extension must be able to bind to port 5600. If the real ActivityWatch desktop server is running, or any other application occupies port 5600, HPR's fake server will fail to start. Always shut down other ActivityWatch instances before starting HPR.

### 2. Loopback IPv4 Binding
The server binds to `127.0.0.1` directly rather than resolving `"localhost"`. This bypasses OS DNS quirks where `"localhost"` resolves to IPv6 `[::1]`, which would cause connection failures if aw-watcher-afk only communicates over IPv4.

### 3. Background Execution Thread
HPR runs this script in a dedicated background thread. The HTTP server blocks this thread waiting for socket connections, but it is fully isolated from HPR's primary loop so there is no UI stutter.

### 4. AFK Timeout
By default, aw-watcher-afk considers you AFK after 3 minutes of no keyboard or mouse input. This threshold is configured on the watcher side, not inside this extension.

---

## How the Extension Works Under the Hood

### Step 1: Initialization
When HPR starts, `init()` runs once:
- Sets extension metadata.
- Starts the HTTP server on port 5600.

### Step 2: HTTP Server Loop
The server registered via `HPR.startServer_E` handles three types of requests from aw-watcher-afk:
- **CORS preflight** (`OPTIONS`): Returns success headers.
- **Bucket registration** (`POST /api/0/buckets/`): Echoes back mock bucket metadata so the watcher passes its validation step.
- **Heartbeats** (`POST /api/0/buckets/.../heartbeat`): Reads `event.data.status` and calls the AFK handler.

### Step 3: AFK State Machine
On every heartbeat:
- If status is `afk` or `hibernating` and tracking is currently active → call `HPR.stopTracking_E`.
- If status is `not-afk` and tracking is currently paused → call `HPR.startTracking_E`.
- Redundant transitions (e.g. afk while already afk) are ignored via the `is_afk` flag.

### Step 4: Shutdown
When HPR exits, `onExit()` runs and logs a clean stop. No database saves or event disconnects are needed since this extension holds no persistent state.

---

## Testing

You can manually test the extension using curl from the command line without needing aw-watcher-afk installed:

**Simulate AFK:**
```cmd
curl -X POST "http://localhost:5600/api/0/buckets/aw-watcher-afk-mock/heartbeat?pulsetime=30" -H "Content-Type: application/json" -d "{\"timestamp\":\"2026-05-29T12:00:00Z\",\"duration\":0,\"data\":{\"status\":\"afk\"}}"
```

**Simulate not-AFK:**
```cmd
curl -X POST "http://localhost:5600/api/0/buckets/aw-watcher-afk-mock/heartbeat?pulsetime=30" -H "Content-Type: application/json" -d "{\"timestamp\":\"2026-05-29T12:00:01Z\",\"duration\":0,\"data\":{\"status\":\"not-afk\"}}"
```

**Simulate hibernating:**
```cmd
curl -X POST "http://localhost:5600/api/0/buckets/aw-watcher-afk-mock/heartbeat?pulsetime=30" -H "Content-Type: application/json" -d "{\"timestamp\":\"2026-05-29T12:00:02Z\",\"duration\":0,\"data\":{\"status\":\"hibernating\"}}"
```

Watch the HPR logs for `stopping tracking` and `resuming tracking` messages to confirm it is working.