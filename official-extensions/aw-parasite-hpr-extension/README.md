# AW URL Parasite HPR Extension

This directory contains the official Human Pattern Recorder (HPR) extension for tracking active web browser sessions using a local loopback integration.

## Description

The AW URL Parasite HPR Extension is a lightweight module designed to monitor and catalog the websites you visit throughout the day. Rather than forcing you to install complex, platform-dependent browser socket trackers directly in your main system paths, this extension operates as a parasitic data consumer. It hooks into the local API exposed by ActivityWatch, a popular open source time-tracker.

ActivityWatch runs a background observer in your browser (via the standard aw-watcher-web browser extension) which broadcasts active tab URLs to a local web server running on port 5600. The HPR script queries that local endpoint, filters and processes the raw tracking payload, stores the accumulated time in HPR's integrated SQLite database, and routes the metrics to a custom Slint UI panel.

This allows developers to enjoy complete web tracking statistics directly within the HPR main desktop panel without bloating the C++ core engine or introducing system-wide browser interceptor hooks.

---

## Installation

To deploy the extension and render the browser tracking dashboard in your active HPR workspace, follow the step-by-step setup instructions below:

### 1. Install the Lua Extension Script
The extension script (`main.lua`) must be placed inside your local HPR config extensions folder. This allows the HPR C++ background loader to scan, initialize, and execute the extension at startup.

* **On Windows**: Copy `main.lua` to:
  ```cmd
  %APPDATA%\HPR\HPR_Config\extensions\main.lua
  ```
* **On Linux**: Copy `main.lua` to:
  ```bash
  ~/.config/HPR/extensions/main.lua
  ```

### 2. Extract and Install the Slint UI Layout Files
The user interface views are packaged inside the `ui.zip` archive. These files declare the custom Slint component layout (`aw-parasite-view.slint`), struct schemas (`types.slint`), and sidebar navigation panels (`app-window.slint`) that draw the visual browser metrics dashboard.

1. Locate the `ui.zip` archive in the extension folder.
2. Extract the contents of `ui.zip` into your HPR configuration user interface directory:
   * **On Windows**: Extract files to `%APPDATA%\HPR\HPR_Config\ui\`
   * **On Linux**: Extract files to `~/.config/HPR/ui/`
3. Ensure that the files are placed directly inside the `ui` folder, maintaining the correct directory layout (for example, `ui/aw-parasite-view.slint` and `ui/types.slint`).

### 3. Enable the Slint UI Interpreter in HPR Configuration
To load the dynamic interface (.slint) files at runtime without rebuilding the application, you must flip a boolean in HPR's main configuration file:
1. Open the HPR config file (`config.csv`) in a text editor:
   * **On Windows**: `%APPDATA%\HPR\HPR_Config\config.csv`
   * **On Linux**: `~/.config/HPR/config.csv`
2. Locate the setting `use-interpreter` and set its value to `true`:
   ```csv
   use-interpreter,true
   ```

### 4. Verify Background Services
The extension relies on external activity feeds. Confirm the following browser tracking services are active:
1. Ensure the main ActivityWatch background application is running on your system.
2. Verify that the `aw-watcher-web` plugin is installed and enabled inside your active web browser.
3. Open your browser and navigate to `http://127.0.0.1:5600` to confirm that the server dashboard is accessible and successfully logging active tabs.
4. Launch or restart HPR. Click the new browser icon in the sidebar to open the Browser Activity view and monitor your web sessions.

---

## Technical Specifications and Settings

The extension relies on native HPR environment settings to operate correctly. Below are the key configuration items defined within the script:

1. **Host Connection Address (`AW_HOST`)**: Set to `127.0.0.1:5600`. This is the local TCP network port where the ActivityWatch server accepts connection heartbeats.
2. **Dynamic Bucket Name (`AW_BUCKET`)**: Resolved automatically at runtime. The local server generates unique bucket directories for different applications (typically formatted as `aw-watcher-web-` followed by the host machine's domain or username).
3. **Heartbeat Timeout (`STALE_THRESHOLD_MS`)**: Configured to 25000 milliseconds (25 seconds). If the local tracking server does not send a fresh heartbeat within this window, the extension assumes you are currently idle or have closed your web browser, stopping time accumulation.
4. **Display Update Rate (`init()` return value)**: Configured to tick every 1000 milliseconds (1 second). This maintains real-time desktop UI accuracy without triggering excessive CPU overhead.
5. **Periodic Data Flush Interval**: Saves memory caches to the physical database every 10000 milliseconds (10 seconds) during active sessions.

---

## SQLite Database Schema

All browser statistics are persisted in HPR's shared database file. The extension isolates its records inside a dedicated, lightweight table:

```sql
CREATE TABLE IF NOT EXISTS aw_parasite_url_usage (
    url         TEXT UNIQUE,
    title       TEXT,
    duration_ms INT
);
```

* **`url`**: The extracted base domain name (such as `google.com` or `github.com`) which acts as the unique primary key to prevent duplicate rows.
* **`title`**: The descriptive page title parsed from the active web session.
* **`duration_ms`**: The cumulative active time spent on that specific domain (stored as a standard integer in milliseconds).

---

## Known Limitations

Before deploying the extension, please review the following technical constraints:

### 1. The Localhost Name Resolution Caveat
Passing `"localhost"` in the host address string triggers the operating system's standard name resolution (via `getaddrinfo`), which prioritizes the IPv6 loopback address `[::1]` over the IPv4 address `127.0.0.1` on modern systems. If the local server (such as the ActivityWatch service) binds strictly and exclusively to the IPv4 address `127.0.0.1`, any request targeting `localhost` fails because the OS tries to connect via `[::1]` first, leading to immediate connection refusals or timeouts. To prevent this connection issue, the script is configured to bypass local DNS lookup by querying the direct IPv4 literal `"127.0.0.1"` directly.

### 2. External Service Dependency
The extension contains no native web interceptor mechanisms. It depends entirely on the pre-existing ActivityWatch server and its corresponding browser plug-in being active on your system. If the local background service or the browser extension is stopped, the data feed will instantly freeze, and the extension will log a connection warning to the diagnostics panel.

### 3. Active Window Tracking Limitations
The extension can only log URLs when your web browser is the active, focused desktop application. If the browser remains open in the background while you are working inside a terminal or code editor, HPR's native window trackers will correctly prioritize the active application, and the URL timer will pause.

### 4. Single-Threaded Event Model
HPR runs each extension script inside an isolated operating system thread. While HPR's network utilities (`HPR.httpGet_E`) are synchronous and block the script's execution path until a response is received, this blocking behavior is completely isolated to the background thread. It has zero negative impact on HPR's primary CPU routines or UI layout rendering.

---

## How the Extension Works under the Hood

This section outlines the step-by-step technical lifecycle of the extension during execution:

### Step 1: Initialization and Database Preloading
When HPR starts up, the extension manager loads the script and executes the `init()` entry hook exactly once. 
* The script registers its identity metadata inside HPR's loader registry by setting `HPR.authorName = "Plexescor"` and `HPR.extensionName = "AW URL Parasite HPR Extension"`.
* It issues a C++ database command (`HPR.dbExecute_E`) to ensure the SQLite tracking table exists.
* It executes a query (`HPR.dbQuery_E`) to load any historical browsing data recorded earlier in the day back into an in-memory Lua table (`url_history`). This prevents restarts or application updates from wiping out your daily tracking progress.
* It sets the thread execution interval by returning `1000` (meaning the script thread will wake up to execute the tick function every 1000 milliseconds).

### Step 2: System Event Rollover Hooks
To keep database operations efficient and synchronized with HPR's global calendar, the script registers three event callbacks via `HPR.connect_E`:
* **`MIDNIGHT_ROLLOVER`**: Clears the in-memory `url_history` cache when the system calendar transitions to a new day.
* **`LOAD_DATABASE_SINGULAR`**: Fired when you select a past calendar day in HPR. The script uses `pcall` and `HPR.dbQueryHistorical_E` to load that specific day's records from HPR's archive directory into a separate memory table (`past_url_history`), toggling the system state to historical view.
* **`LOAD_LIVE_DATA`**: Fired when you switch back to real-time tracking, reverting the active display source back to the primary live memory table.

### Step 3: The Periodic Tick Cycle (`onTick`)
Every second, the thread scheduler invokes the `onTick(delta)` loop, passing the precise time delta (in milliseconds) since the last execution.
1. **Dynamic Bucket Discovery (`discoverBucket`)**: On its first run, the script queries `/api/0/buckets/`. It decodes the returned JSON dictionary using `HPR.parseJSON_E` to search for a bucket name containing the browser watcher prefix (`aw-watcher-web`). It caches this ID to avoid repeating directory scans on subsequent ticks.
2. **Active Session Querying (`fetchLatestUrl`)**: The script requests the most recent event from the browser bucket. It parses the JSON string using `HPR.parseJSON_E` to extract the `url` and the page `title`.
3. **Domain Sanitization**: The raw URL is routed through a regex helper (`extractDomain`) to strip away full URL sub-paths, tracking parameters, and `www.` subdomains, yielding a clean domain identity (e.g. converting `https://www.github.com/plexescor` to `github.com`).
4. **Time Accumulation and Stale Filtering**: If a valid URL is returned, the script resets its idle timer. If the idle timer remains below the stale threshold, the elapsed time delta is added to the domain's duration value in the memory table. If no URL is returned (e.g. browser closed), the idle timer increments until it passes the stale threshold, pausing all time counting.

### Step 4: UI Updating and Thread Communication
After updating the memory table, the script prepares a serialized view model to refresh the visual panel:
* It compiles the raw time values into a formatted list of rows, converting raw milliseconds into human-readable duration strings (using `HPR.formatTime_HHMMSS_E`).
* It sorts the list in descending order, putting the most-visited domain at the top.
* It calls `HPR.setUiProperty_E("awUrls_S", formatted)` and `HPR.setUiProperty_E("trackedTime_Aw_S", total_ms)` to push the data model across the thread boundary into HPR's root Slint UI layout. The Slint engine automatically updates the graphical bars and browser percentages in the desktop dashboard.

### Step 5: Periodic Database Flushing
To minimize write operations and prolong solid-state drive life, the script caches updates in memory. It tracks the elapsed time and executes a database save (`flushToDatabase`) every 10 seconds, writing all modified memory values back to HPR's persistent SQLite database.

### Step 6: Teardown and Resource Cleanup
When the user closes HPR or disables the extension, the thread manager fires the `onExit()` hook:
* The script executes a blocking, final database flush to ensure no tracked seconds are lost during system shutdown.
* It explicitly disconnects its three event subscriptions (`midnightId`, `pastDbId`, and `liveDbId`) via `HPR.disconnect_E`. This releases the C++ event listener handles, allowing the Lua garbage collector to free resources and preventing application memory leaks or crashes during subsequent reloads.
