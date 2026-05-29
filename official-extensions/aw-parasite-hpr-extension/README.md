# AW URL Parasite HPR Extension

This extension is designed to leech off the official ActivityWatch browser extension (like aw-watcher-web for Chrome or Firefox). It acts as a lightweight server inside HPR, captures your web browser activity, and displays your most visited websites in the HPR dashboard.

It does NOT require the actual ActivityWatch desktop application to see or track your browser URLs. HPR mimics the ActivityWatch server, allowing you to track your browser history with a very light memory footprint.

---

## Description

The AW URL Parasite HPR Extension is a lightweight module designed to monitor and catalog the websites you visit throughout the day. Instead of running the heavy ActivityWatch desktop suite, this extension operates as a local receiver. It hooks directly into the telemetry sent by your web browser's tracking extension.

The official browser extension (aw-watcher-web) sends active tab URLs to a local web server running on port 5600. Our HPR script starts a fake server on this exact port, captures these incoming requests, reads the URL and title, stores the active time in HPR's built-in SQLite database, and updates the custom Slint UI panel.

This allows you to enjoy web tracking statistics directly within the HPR main desktop panel without running any heavy background software or slowing down your computer.

---

## Installation

Follow these steps to install the extension and view your web browsing history inside HPR:

### 1. Install the Lua Extension Script
You must place the `main.lua` script inside HPR's extension directory so that the background loader can find and run it when the application starts.

* **On Windows**: Copy `main.lua` to:
  ```cmd
  %APPDATA%\HPR\HPR_Config\extensions\main.lua
  ```
* **On Linux**: Copy `main.lua` to:
  ```bash
  ~/.config/HPR/extensions/main.lua
  ```

### 2. Extract and Install the Slint UI Files
The interface components are packaged inside the `ui.zip` archive.
1. Extract the contents of `ui.zip`.
2. Move the extracted files into HPR's user interface directory:
   * **On Windows**: `%APPDATA%\HPR\HPR_Config\ui\`
   * **On Linux**: `~/.config/HPR/ui/`
3. Make sure the files (such as `aw-parasite-view.slint` and `types.slint`) are placed directly inside that folder.

### 3. Enable the UI Interpreter in HPR Config
To load the dynamic interface (.slint) files on startup without rebuilding:
1. Open the HPR config file (`config.csv`) in a text editor:
   * **On Windows**: `%APPDATA%\HPR\HPR_Config\config.csv`
   * **On Linux**: `~/.config/HPR/config.csv`
2. Find the setting named `use-interpreter` and make sure it is set to `true`:
   ```csv
   use-interpreter,true
   ```

### 4. Set Up the Browser Watcher (The Leech Source)
1. Install the official **ActivityWatch Web Watcher** (`aw-watcher-web`) extension in your Chrome, Firefox, or Brave browser.
2. Ensure the real ActivityWatch desktop application is **not** running (otherwise, HPR cannot bind to port 5600).
3. Start HPR. The browser extension will automatically discover HPR's fake server and start sending active tabs.
4. Click the browser globe icon in the HPR sidebar to view your live web session history.

---

## Technical Specifications and Settings

The script sets up and configures the fake server using the following parameters:

1. **Port (5600)**: This is the default port used by all ActivityWatch watchers. HPR listens exclusively on `127.0.0.1:5600`.
2. **CORS Options**: The server automatically responds to `OPTIONS` requests from the browser to bypass cross-origin browser security restrictions.
3. **Bucket Validation**: When the browser watcher sends a request to register its tracking folder (bucket), the script responds with a mocked bucket configuration (including a dummy ID and creation date) to satisfy the client's strict validation checks.
4. **Stale Threshold (85 seconds)**: Since browser extensions often send heartbeats in batches to save computer energy, we set a lenient threshold of 85,000 milliseconds. If the gap between two event times exceeds this threshold, the script assumes you were away or closed the browser, pausing the timer.
5. **AGGREGATION**: Web addresses are parsed to extract only the main domain (for example, converting `https://www.youtube.com/watch?v=123` into `youtube.com`). This ensures that time spent on different pages of the same site is grouped together.

---

## SQLite Database Schema

All tracking records are saved inside HPR's central SQLite database. The script creates and manages a dedicated table:

```sql
CREATE TABLE IF NOT EXISTS aw_parasite_url_usage (
    url         TEXT UNIQUE,
    title       TEXT,
    duration_ms INT
);
```

* **`url`**: The extracted base domain name (such as `google.com` or `youtube.com`) which acts as the unique primary key to prevent duplicate entries.
* **`title`**: The descriptive tab title sent by the browser.
* **`duration_ms`**: The total active time spent on that domain in milliseconds.

---

## Known Limitations

Before using the extension, please note these technical details:

### 1. Active Window Tracking
The extension only accumulates active time when your web browser is the focused window on your screen. If your browser remains open in the background while you are working in a terminal or code editor, the timer for the active website will pause.

### 2. Port Binding Conflicts
The extension must be able to bind to port 5600. If you have the real ActivityWatch desktop server running, or another application using port 5600, HPR's fake server will fail to start. Always shut down other ActivityWatch server instances before starting HPR.

### 3. Loopback IPv4 Binding
The server binds directly to the literal loopback IP address `127.0.0.1` rather than resolving the string `"localhost"`. This bypasses modern operating system DNS lookup quirks where `"localhost"` resolves to the IPv6 address `[::1]`, which would cause connection failures if the client only talks over IPv4.

### 4. Background Execution Thread
HPR executes this script inside a dedicated background thread. Although the HTTP server blocks the execution thread to wait for socket connections, it is isolated from HPR's primary loop. This prevents any graphical stutter or delay in the desktop UI.

---

## How the Extension Works Under the Hood

Here is the step-by-step cycle of what happens when the extension is active:

### Step 1: Initialization and Database Load
When HPR starts up, the extension engine loads the script and executes the `init()` function once:
- The script sets its metadata (`HPR.authorName` and `HPR.extensionName`).
- It executes a SQL statement to make sure the tracking table exists.
- It loads all previously recorded domain times from the database into an in-memory Lua table (`url_history`). This ensures you do not lose your daily progress when restarting HPR.
- It returns `1000`, scheduling HPR's tick manager to keep the thread alive.

### Step 2: System Event Hooks
The script connects to three global HPR events using `HPR.connect_E`:
- **`MIDNIGHT_ROLLOVER`**: Clears your live tracking history automatically when the calendar flips to a new day.
- **`LOAD_DATABASE_SINGULAR`**: Fired when you select a past calendar date in HPR, querying the archive files using `HPR.dbQueryHistorical_E` to display your past browsing history.
- **`LOAD_LIVE_DATA`**: Fired when you switch back to real-time view, restoring the main tracking list to your display.

### Step 3: HTTP Server loop
The script registers a callback via `HPR.startServer_E`. The C++ socket engine opens a socket on port 5600:
- It processes CORS preflight checks (`OPTIONS`) and returns successful headers.
- It handles bucket registration requests by echo-returning mock bucket metadata containing a valid ID.
- It receives heartbeat packages containing raw JSON telemetry with a list of browsed links and event timestamps.

### Step 4: Tracking calculations
When a heartbeat arrives, the script extracts the tab's URL and title along with the browser's raw UTC event timestamp (`event.timestamp`):
- It parses the timestamp using `HPR.parseISO8601_E`.
- It subtracts the previous event's timestamp from the current one to calculate the exact millisecond duration of your visit.
- If the duration is valid and falls under the 85-second threshold, the duration is added to the domain's aggregate score in the memory table.
- The UI is immediately refreshed with the sorted rankings.

### Step 5: Database Saves
To prevent constant disk writes, the script keeps updates in memory and flushes them to the physical SQLite file every 10 seconds.

### Step 6: Shutdown and Resource Cleanup
When you exit HPR or reload the extensions:
- The script executes `onExit()`, doing a final database save to ensure no tracked seconds are lost.
- It disconnects its global event handles (`midnightId`, `pastDbId`, `liveDbId`) to free memory and prevent leaks inside the host C++ application.
