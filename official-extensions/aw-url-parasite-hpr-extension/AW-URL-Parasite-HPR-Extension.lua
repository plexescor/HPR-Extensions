-- ============================================================
--  AW URL Parasite HPR Extension
--  Author: Plexescor
--
--  What this does:
--  Starts an HTTP server on port 5600 (ActivityWatch default).
--  Receives heartbeat telemetry from ActivityWatch watchers 
--  (like aw-watcher-web in your browser) directly, processes 
--  durations, updates the HPR database and the Slint UI.
--
--  Requirement:
--  Point your aw-watcher-web browser extension at HPR (localhost:5600)
--  and it will record everything without running the real ActivityWatch!
-- ============================================================

-- ── State ────────────────────────────────────────────────────
local url_history = {}
local past_url_history = {}
local is_showing_historical = false

-- Time-tracking state for server-driven heartbeats
local last_heartbeat_time = nil
local last_seen_url = nil
local last_seen_title = nil
local last_flush_time = 0

-- Event subscription IDs
local midnightId = 0
local pastDbId   = 0
local liveDbId   = 0

-- ── Helpers ──────────────────────────────────────────────────

-- Turns "https://www.youtube.com/watch?v=xyz" into "youtube.com"
local function extractDomain(url)
    local domain = url:match("^https?://([^/]+)") or url
    domain = domain:match("^www%.(.+)") or domain
    domain = domain:match("^([^:]+)") or domain
    return domain
end

-- Saves all tracked URLs and their durations to HPR's SQLite database.
local function flushToDatabase()
    for url, data in pairs(url_history) do
        HPR.dbExecute_E(
            "insert or replace into aw_parasite_url_usage (url, title, duration_ms) values (?, ?, ?);",
            { url, data.title, tostring(math.floor(data.duration_ms)) }
        )
    end
end

-- Refreshes HPR UI with the sorted list and total duration (aggregated by domain)
local function updateUI()
    local source    = is_showing_historical and past_url_history or url_history
    local aggregated = {}
    local total_ms  = 0

    for u, data in pairs(source) do
        local domain = extractDomain(u)
        total_ms = total_ms + data.duration_ms
        
        if not aggregated[domain] then
            aggregated[domain] = {
                title = domain,
                duration_ms = 0
            }
        end
        aggregated[domain].duration_ms = aggregated[domain].duration_ms + data.duration_ms
    end

    local formatted = {}
    for domain, data in pairs(aggregated) do
        table.insert(formatted, {
            url        = domain,
            title      = domain,
            duration   = HPR.formatTime_HHMMSS_E(math.floor(data.duration_ms)),
            duration_i = math.floor(data.duration_ms)
        })
    end

    -- Sort by most time spent first
    table.sort(formatted, function(a, b)
        return a.duration_i > b.duration_i
    end)

    HPR.setUiProperty_E("awUrls_S", formatted)
    HPR.setUiProperty_E("trackedTime_Aw_S", math.floor(total_ms))
end

-- ── Core Server Event Handler ─────────────────────────────────
local function processHeartbeat(url, title, timestamp_str)
    if not url or url == "" then return end

    local now = HPR.parseISO8601_E(timestamp_str) or HPR.getTime_MS()
    if last_heartbeat_time then
        local elapsed_ms = now - last_heartbeat_time
        
        -- If heartbeat is active (less than 85 seconds between requests)
        if elapsed_ms > 0 and elapsed_ms < 85000 then
            if last_seen_url then
                if not url_history[last_seen_url] then
                    url_history[last_seen_url] = { title = last_seen_title or last_seen_url, duration_ms = 0 }
                end
                url_history[last_seen_url].duration_ms = url_history[last_seen_url].duration_ms + elapsed_ms
                url_history[last_seen_url].title = last_seen_title
            end
        end
    end

    last_heartbeat_time = now
    last_seen_url = url
    last_seen_title = title

    -- Trigger live UI redraw
    updateUI()

    -- Flush to database every 10 seconds (10000ms)
    if now - last_flush_time >= 10000 then
        local ok, err = pcall(flushToDatabase)
        if not ok then print("[aw_server] DB Flush error: " .. tostring(err)) end
        last_flush_time = now
    end
end

-- ── Lifecycle ────────────────────────────────────────────────

function init()
    HPR.authorName    = "Plexescor"
    HPR.extensionName = "AW URL Parasite HPR Extension"

    -- Wait until Slint UI is fully active so UI properties are pushed successfully
    print("[aw_server] Waiting for Slint UI to initialize...")
    while not HPR.isUiActive_E() do
        HPR.sleep_E(100)
    end
    print("[aw_server] Slint UI is active! Continuing startup...")

    -- Create database schema
    HPR.dbExecute_E([[
        create table if not exists aw_parasite_url_usage (
            url         text unique,
            title       text,
            duration_ms int
        );
    ]])

    -- Load saved history into memory
    local rows = HPR.dbQuery_E("select url, title, duration_ms from aw_parasite_url_usage;")
    for _, row in ipairs(rows) do
        url_history[row.url] = {
            title       = row.title,
            duration_ms = tonumber(row.duration_ms) or 0
        }
    end
    print("[aw_server] loaded " .. #rows .. " URLs from database")

    -- Midnight Roll-Over
    midnightId = HPR.connect_E("MIDNIGHT_ROLLOVER", function()
        url_history = {}
        last_heartbeat_time = nil
        last_seen_url = nil
        updateUI()
    end)

    -- Historical calendar view hooks
    pastDbId = HPR.connect_E("LOAD_DATABASE_SINGULAR", function()
        local ok, histRows = pcall(HPR.dbQueryHistorical_E,
            "select url, title, duration_ms from aw_parasite_url_usage;")
        if ok and histRows and #histRows > 0 then
            past_url_history = {}
            for _, row in ipairs(histRows) do
                past_url_history[row.url] = {
                    title       = row.title,
                    duration_ms = tonumber(row.duration_ms) or 0
                }
            end
            is_showing_historical = true
        else
            past_url_history    = {}
            is_showing_historical = false
        end
        updateUI()
    end)

    -- Return to live view
    liveDbId = HPR.connect_E("LOAD_LIVE_DATA", function()
        is_showing_historical = false
        updateUI()
    end)

    -- Initial UI draw
    updateUI()

    -- Start the generic C++ HTTP Server on port 5600
    print("[aw_server] starting HTTP Server on 127.0.0.1:5600...")
    local ok = HPR.startServer_E(5600, function(req)
        
        -- 1. CORS Preflight
        if req.method == "OPTIONS" then
            return {
                status = 204,
                headers = {
                    ["Access-Control-Allow-Origin"]  = "*",
                    ["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS",
                    ["Access-Control-Allow-Headers"] = "Content-Type"
                },
                body = ""
            }
        end

        -- 2. Mock Bucket Discovery / Bucket Query
        if req.method == "GET" and string.find(req.path, "/api/0/buckets") then
            local hostname = "localhost"
            local bucket_id = "aw-watcher-web-mock"
            local mock_buckets = {
                [bucket_id] = {
                    id = bucket_id,
                    created = "2026-05-29T12:00:00Z",
                    name = "Browser Watcher",
                    type = "web.tab.current",
                    client = "aw-watcher-web",
                    hostname = hostname
                }
            }
            return {
                status = 200,
                headers = {
                    ["Content-Type"] = "application/json",
                    ["Access-Control-Allow-Origin"] = "*"
                },
                body = HPR.toJSON_E(mock_buckets)
            }
        end

        -- 3. Mock Bucket Creation (Echo back full standard bucket metadata to satisfy client verification!)
        if req.method == "POST" and string.find(req.path, "/api/0/buckets/") and not string.find(req.path, "/heartbeat") then
            local bucket_info = HPR.parseJSON_E(req.body) or {}
            
            local bucket_id = req.path:match("/api/0/buckets/([^/]+)") or "aw-watcher-web-mock"
            bucket_info.id = bucket_id
            bucket_info.created = "2026-05-29T12:00:00Z"
            
            return {
                status = 200,
                headers = {
                    ["Content-Type"] = "application/json",
                    ["Access-Control-Allow-Origin"] = "*"
                },
                body = HPR.toJSON_E(bucket_info)
            }
        end

        -- 4. Process Telemetry / Heartbeats (Echo back exact event object with an ID to satisfy standard watcher validation!)
        if req.method == "POST" and string.find(req.path, "/heartbeat") then
            local event = HPR.parseJSON_E(req.body)
            
            if event then
                event.id = 12345 -- Mock event ID for client tracking
                if event.data then
                    local url = event.data.url
                    local title = event.data.title or url
                    processHeartbeat(url, title, event.timestamp)
                end
            end

            return {
                status = 200,
                headers = {
                    ["Content-Type"] = "application/json",
                    ["Access-Control-Allow-Origin"] = "*"
                },
                body = HPR.toJSON_E(event)
            }
        end

        -- Fallback 404
        return {
            status = 404,
            headers = { ["Access-Control-Allow-Origin"] = "*" },
            body = "Endpoint Not Found"
        }
    end)

    if ok then
        print("[aw_server] server listening successfully on port 5600!")
    else
        print("[aw_server] FAILED to start HTTP server. Check if port 5600 is already in use!")
    end

    return 1000
end

function onTick(delta)
    -- Running the server blocks the extension main loop, which is expected!
    -- Timing tracking is completely driven in real-time by incoming HTTP requests.
end

function onExit()
    -- Save any remaining state before exit
    flushToDatabase()

    -- Disconnect events to prevent leaks
    HPR.disconnect_E("MIDNIGHT_ROLLOVER", midnightId)
    HPR.disconnect_E("LOAD_DATABASE_SINGULAR", pastDbId)
    HPR.disconnect_E("LOAD_LIVE_DATA", liveDbId)

    print("[aw_server] server stopped and database saved cleanly")
end
