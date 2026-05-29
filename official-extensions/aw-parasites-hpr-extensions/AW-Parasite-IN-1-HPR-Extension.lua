-- ============================================================
--  AW Parasite HPR Extension
--  Author: Plexescor
--
--  What this does:
--  Starts a single HTTP server on port 5600 (ActivityWatch default).
--  Handles both aw-watcher-web (URL tracking) and aw-watcher-afk
--  (AFK detection) on the same port, routing by bucket type.
--
--  Requirement:
--  Point aw-watcher-web and aw-watcher-afk at HPR (localhost:5600)
--  and it will record everything without running the real ActivityWatch!
-- ============================================================

-- ── URL Tracking State ───────────────────────────────────────
local url_history = {}
local past_url_history = {}
local is_showing_historical = false

local last_heartbeat_time = nil
local last_seen_url = nil
local last_seen_title = nil
local last_flush_time = 0

-- ── AFK State ────────────────────────────────────────────────
local is_afk = false

-- ── Event Subscription IDs ───────────────────────────────────
local midnightId = 0
local pastDbId   = 0
local liveDbId   = 0

-- ── URL Helpers ──────────────────────────────────────────────

local function extractDomain(url)
    local domain = url:match("^https?://([^/]+)") or url
    domain = domain:match("^www%.(.+)") or domain
    domain = domain:match("^([^:]+)") or domain
    return domain
end

local function flushToDatabase()
    for url, data in pairs(url_history) do
        HPR.dbExecute_E(
            "insert or replace into aw_parasite_url_usage (url, title, duration_ms) values (?, ?, ?);",
            { url, data.title, tostring(math.floor(data.duration_ms)) }
        )
    end
end

local function updateUI()
    local source     = is_showing_historical and past_url_history or url_history
    local aggregated = {}
    local total_ms   = 0

    for u, data in pairs(source) do
        local domain = extractDomain(u)
        total_ms = total_ms + data.duration_ms
        if not aggregated[domain] then
            aggregated[domain] = { title = domain, duration_ms = 0 }
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

    table.sort(formatted, function(a, b) return a.duration_i > b.duration_i end)

    HPR.setUiProperty_E("awUrls_S", formatted)
    HPR.setUiProperty_E("trackedTime_Aw_S", math.floor(total_ms))
end

-- ── URL Heartbeat Handler ─────────────────────────────────────
local function processUrlHeartbeat(url, title, timestamp_str)
    if not url or url == "" then return end
    if is_afk then return end

    local now = HPR.parseISO8601_E(timestamp_str) or HPR.getTime_MS()
    if last_heartbeat_time then
        local elapsed_ms = now - last_heartbeat_time
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

    updateUI()

    if now - last_flush_time >= 10000 then
        local ok, err = pcall(flushToDatabase)
        if not ok then print("[aw_parasite] DB flush error: " .. tostring(err)) end
        last_flush_time = now
    end
end

-- ── AFK Heartbeat Handler ─────────────────────────────────────
local function processAfkHeartbeat(status)
    local afk_now = (status == "afk" or status == "hibernating")

    if afk_now then
        if not is_afk then
            is_afk = true
            last_heartbeat_time = nil -- don't count AFK gap as URL time
            print("[aw_parasite] user is AFK/hibernating — stopping tracking")
            local ok, err = pcall(HPR.stopTracking_E)
            if not ok then print("[aw_parasite] stopTracking_E error: " .. tostring(err)) end
        end
    else
        if is_afk then
            is_afk = false
            last_heartbeat_time = nil -- start fresh on return
            print("[aw_parasite] user returned — resuming tracking")
            local ok, err = pcall(HPR.startTracking_E)
            if not ok then print("[aw_parasite] startTracking_E error: " .. tostring(err)) end
        end
    end
end

-- ── Lifecycle ────────────────────────────────────────────────

function init()
    HPR.authorName    = "Plexescor"
    HPR.extensionName = "AW Parasite HPR Extension"

    print("[aw_parasite] waiting for Slint UI to initialize...")
    while not HPR.isUiActive_E() do
        HPR.sleep_E(100)
    end
    print("[aw_parasite] Slint UI active, continuing startup...")

    -- Database setup
    HPR.dbExecute_E([[
        create table if not exists aw_parasite_url_usage (
            url         text unique,
            title       text,
            duration_ms int
        );
    ]])

    local rows = HPR.dbQuery_E("select url, title, duration_ms from aw_parasite_url_usage;")
    for _, row in ipairs(rows) do
        url_history[row.url] = {
            title       = row.title,
            duration_ms = tonumber(row.duration_ms) or 0
        }
    end
    print("[aw_parasite] loaded " .. #rows .. " URLs from database")

    -- Events
    midnightId = HPR.connect_E("MIDNIGHT_ROLLOVER", function()
        url_history = {}
        last_heartbeat_time = nil
        last_seen_url = nil
        updateUI()
    end)

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
            past_url_history      = {}
            is_showing_historical = false
        end
        updateUI()
    end)

    liveDbId = HPR.connect_E("LOAD_LIVE_DATA", function()
        is_showing_historical = false
        updateUI()
    end)

    updateUI()

    -- Single server handles both watchers
    print("[aw_parasite] starting HTTP server on 127.0.0.1:5600...")
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

        -- 2. Bucket Discovery — return both mock buckets
        if req.method == "GET" and string.find(req.path, "/api/0/buckets") then
            return {
                status = 200,
                headers = {
                    ["Content-Type"]                = "application/json",
                    ["Access-Control-Allow-Origin"] = "*"
                },
                body = HPR.toJSON_E({
                    ["aw-watcher-web-mock"] = {
                        id       = "aw-watcher-web-mock",
                        created  = "2026-05-29T12:00:00Z",
                        name     = "Browser Watcher",
                        type     = "web.tab.current",
                        client   = "aw-watcher-web",
                        hostname = "localhost"
                    },
                    ["aw-watcher-afk-mock"] = {
                        id       = "aw-watcher-afk-mock",
                        created  = "2026-05-29T12:00:00Z",
                        name     = "AFK Watcher",
                        type     = "afkstatus",
                        client   = "aw-watcher-afk",
                        hostname = "localhost"
                    }
                })
            }
        end

        -- 3. Bucket Creation
        if req.method == "POST" and string.find(req.path, "/api/0/buckets/") and not string.find(req.path, "/heartbeat") then
            local bucket_info = HPR.parseJSON_E(req.body) or {}
            bucket_info.id      = req.path:match("/api/0/buckets/([^/]+)") or "aw-mock"
            bucket_info.created = "2026-05-29T12:00:00Z"
            return {
                status = 200,
                headers = {
                    ["Content-Type"]                = "application/json",
                    ["Access-Control-Allow-Origin"] = "*"
                },
                body = HPR.toJSON_E(bucket_info)
            }
        end

        -- 4. Heartbeats — route by bucket name in path
        if req.method == "POST" and string.find(req.path, "/heartbeat") then
            local event = HPR.parseJSON_E(req.body)

            if event and event.data then
                event.id = 12345
                if string.find(req.path, "aw-watcher-afk") then
                    processAfkHeartbeat(event.data.status)
                else
                    processUrlHeartbeat(event.data.url, event.data.title or event.data.url, event.timestamp)
                end
            end

            return {
                status = 200,
                headers = {
                    ["Content-Type"]                = "application/json",
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
        print("[aw_parasite] server listening successfully on port 5600!")
    else
        print("[aw_parasite] FAILED to start HTTP server. Check if port 5600 is already in use!")
    end

    return 1000
end

function onTick(delta) end

function onExit()
    flushToDatabase()
    HPR.disconnect_E("MIDNIGHT_ROLLOVER", midnightId)
    HPR.disconnect_E("LOAD_DATABASE_SINGULAR", pastDbId)
    HPR.disconnect_E("LOAD_LIVE_DATA", liveDbId)
    print("[aw_parasite] server stopped and database saved cleanly")
end