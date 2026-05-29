# AW Parasite HPR Extension

This extension leeches off the official ActivityWatch watchers (aw-watcher-web and aw-watcher-afk). It acts as a single lightweight server inside HPR, captures your web browser activity, displays your most visited websites in the HPR dashboard, and automatically pauses/resumes HPR tracking based on whether you are active at your computer.

It does NOT require the actual ActivityWatch desktop application. HPR mimics the ActivityWatch server on a single port, handling both watchers simultaneously with a near-zero memory footprint.

---

## Description

The AW Parasite HPR Extension is a lightweight module that handles two jobs at once on a single HTTP server running on port 5600.

**URL Tracking**: The official browser extension (aw-watcher-web) sends active tab URLs to port 5600. HPR captures these requests, reads the URL and title, stores the active time in HPR's built-in SQLite database, and updates the custom Slint UI panel. This lets you see web tracking statistics directly inside HPR without running any heavy background software.

**AFK Detection**: aw-watcher-afk sends periodic heartbeats containing a status field (`afk`, `not-afk`, or `hibernating`). HPR reads the incoming status and calls `HPR.stopTracking_E` when you go AFK or hibernate, and `HPR.startTracking_E` when you return. URL time is also automatically paused during AFK periods so no phantom time accumulates.

---

## Installation

### 1. Install the Lua Extension Script
Place `main.lua` inside HPR's extension directory:

* **On Windows**: `%APPDATA%\HPR\HPR_Config\extensions\main.lua`
* **On Linux**: `~/.config/HPR/extensions/main.lua`

### 2. Extract and Install the Slint UI Files
The interface components are packaged inside the `ui.zip` archive.
1. Extract the contents of `ui.zip`.
2. Move the extracted files into HPR's user interface directory:
   * **On Windows**: `%APPDATA%\HPR\HPR_Config\ui\`
   * **On Linux**: `~/.config/HPR/ui/`
3. Make sure the files (such as `aw-parasite-view.slint` and `types.slint`) are placed directly inside that folder.

### 3. Enable the UI Interpreter in HPR Config
1. Open the HPR config file (`config.csv`) in a text editor:
   * **On Windows**: `%APPDATA%\HPR\HPR_Config\config.csv`
   * **On Linux**: `~/.config/HPR/config.csv`
2. Find the setting named `use-interpreter` and make sure it is set to `true`:
```csv
   use-interpreter,true
```

### 4. Set Up the Browser Watcher
1. Install the official **ActivityWatch Web Watcher** (`aw-watcher-web`) extension in your Chrome, Firefox, or Brave browser.
2. Start HPR. The browser extension will automatically discover HPR's fake server and start sending active tabs.
3. Click the browser globe icon in the HPR sidebar to view your live web session history.

### 5. Set Up the AFK Watcher
1. Download and install `aw-watcher-afk` from the official ActivityWatch releases. You do NOT need the full ActivityWatch suite — only the standalone watcher binary.
2. In aw-watcher-afk's config file, point it at HPR:
```ini
   [aw-watcher-afk]
   host = localhost
   port = 5600
```

### 6. Make Sure ActivityWatch Is Not Running
The real ActivityWatch desktop application must not be running, otherwise it will occupy port 5600 before HPR can bind to it.

---

## Technical Specifications

1. **Port (5600)**: The default port used by all ActivityWatch watchers. HPR listens exclusively on `127.0.0.1:5600` and serves both aw-watcher-web and aw-watcher-afk on the same socket.
2. **CORS Options**: The server automatically responds to `OPTIONS` preflight requests to satisfy both watcher clients.
3. **Bucket Validation**: When either watcher registers its bucket on startup, HPR echoes back a mocked bucket configuration to satisfy the client's validation checks.
4. **Heartbeat Routing**: Incoming heartbeats are routed by bucket name in the request path. Paths containing `aw-watcher-afk` go to the AFK handler; everything else goes to the URL handler.
5. **Stale Threshold (85 seconds)**: Browser extensions often send heartbeats in batches. If the gap between two URL events exceeds 85 seconds, the script assumes you were away or closed the browser and pauses the timer.
6. **AFK Status Values**: The extension handles all three possible status values sent by aw-watcher-afk:
   - `not-afk` — you are active, tracking resumes
   - `afk` — no keyboard/mouse activity detected, tracking pauses
   - `hibernating` — machine woke from sleep, treated the same as afk until activity resumes
7. **AFK Gap Protection**: When you go AFK, `last_heartbeat_time` is reset so no URL time is counted for the gap while you were away.
8. **Domain Aggregation**: Web addresses are parsed to extract only the main domain (e.g. `https://www.youtube.com/watch?v=123` becomes `youtube.com`). Time spent across different pages of the same site is grouped together.

---

## SQLite Database Schema

All URL tracking records are saved inside HPR's central SQLite database:

```sql
CREATE TABLE IF NOT EXISTS aw_parasite_url_usage (
    url         TEXT UNIQUE,
    title       TEXT,
    duration_ms INT
);
```

* **`url`**: The extracted base domain name (such as `google.com` or `youtube.com`), which acts as the unique primary key.
* **`title`**: The descriptive tab title sent by the browser.
* **`duration_ms`**: The total active time spent on that domain in milliseconds.

AFK state is not persisted — it is derived entirely from live heartbeats and resets to `not-afk` on every startup.

---

## Known Limitations

### 1. Port Binding Conflicts
Both watchers share port 5600 through HPR's single server. If the real ActivityWatch desktop application or any other service occupies port 5600, HPR's server will fail to start entirely.

### 2. Loopback IPv4 Binding
The server binds to `127.0.0.1` directly rather than resolving `"localhost"`. This bypasses OS DNS quirks where `"localhost"` resolves to IPv6 `[::1]`, which would cause connection failures if either watcher only communicates over IPv4.

### 3. Background Execution Thread
HPR runs this script in a dedicated background thread. The HTTP server blocks this thread waiting for socket connections, but it is fully isolated from HPR's primary loop so there is no UI stutter.

### 4. AFK Timeout
By default, aw-watcher-afk considers you AFK after 3 minutes of no keyboard or mouse input. This threshold is configured on the watcher side, not inside this extension.

---

## How the Extension Works Under the Hood

### Step 1: Initialization and Database Load
When HPR starts, `init()` runs once:
- Sets extension metadata.
- Creates the `aw_parasite_url_usage` table if it does not exist.
- Loads all previously recorded domain times from the database into the in-memory `url_history` table so daily progress is not lost on restart.
- Waits for the Slint UI to become active before pushing any UI properties.

### Step 2: System Event Hooks
The script connects to three global HPR events:
- **`MIDNIGHT_ROLLOVER`**: Clears live URL tracking history when the calendar flips to a new day.
- **`LOAD_DATABASE_SINGULAR`**: Fired when you select a past calendar date in HPR, queries the archive using `HPR.dbQueryHistorical_E` to display historical browsing data.
- **`LOAD_LIVE_DATA`**: Fired when you switch back to real-time view, restoring the live tracking list.

### Step 3: HTTP Server Loop
The single server registered via `HPR.startServer_E` handles all incoming requests from both watchers:
- **CORS preflight** (`OPTIONS`): Returns success headers.
- **Bucket discovery** (`GET /api/0/buckets`): Returns mock metadata for both `aw-watcher-web-mock` and `aw-watcher-afk-mock`.
- **Bucket registration** (`POST /api/0/buckets/`): Echoes back mock bucket metadata so each watcher passes its validation step.
- **Heartbeats** (`POST /api/0/buckets/.../heartbeat`): Routes to the URL handler or AFK handler based on the bucket name in the path.

### Step 4: URL Tracking
When a URL heartbeat arrives:
- The timestamp is parsed and subtracted from the previous one to calculate elapsed milliseconds.
- If the gap is under 85 seconds and the user is not AFK, the duration is added to that domain's aggregate in memory.
- The Slint UI is immediately refreshed with the sorted domain rankings.
- Every 10 seconds the in-memory table is flushed to SQLite to avoid constant disk writes.

### Step 5: AFK State Machine
On every AFK heartbeat:
- If status is `afk` or `hibernating` and tracking is active → call `HPR.stopTracking_E` and reset `last_heartbeat_time`.
- If status is `not-afk` and tracking is paused → call `HPR.startTracking_E` and reset `last_heartbeat_time`.
- Redundant transitions are ignored via the `is_afk` flag.

### Step 6: Shutdown and Cleanup
When HPR exits, `onExit()`:
- Does a final flush of URL data to SQLite so no tracked seconds are lost.
- Disconnects all three event subscriptions to prevent memory leaks in HPR's C++ event registry.

---

## Testing

You can manually test both handlers using curl without needing the watchers installed.

**Simulate a URL heartbeat:**
```cmd
curl -X POST "http://localhost:5600/api/0/buckets/aw-watcher-web-mock/heartbeat?pulsetime=60" -H "Content-Type: application/json" -d "{\"timestamp\":\"2026-05-29T12:00:00Z\",\"duration\":0,\"data\":{\"url\":\"https://github.com\",\"title\":\"GitHub\"}}"
```

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

Watch the HPR logs for `stopping tracking`, `resuming tracking`, and URL domain updates to confirm everything is working.