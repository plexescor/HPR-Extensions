-- ============================================================
--  AW URL Parasite — HPR Extension
--  Author: Plexescor
--
--  What this does:
--  Reads the currently active browser tab from ActivityWatch
--  (which must be running) and tracks how long you spend on
--  each website. Data is saved to HPR's database and shown
--  in the Browser Activity view.
--
--  Requirements:
--  - ActivityWatch installed and running
--  - aw-watcher-web browser extension installed and active
-- ============================================================

-- ── State ────────────────────────────────────────────────────
-- Stores time spent per URL for today
local url_history = {}

-- Stores time spent per URL when viewing a past day
local past_url_history = {}

-- Whether we are viewing a past day or live data
local is_showing_historical = false

-- Timers
local time_since_last_flush = 0   -- how long since we last saved to DB
local time_since_last_event = 0   -- how long since AW last gave us a fresh URL

-- Event subscription IDs (needed to clean up on exit)
local midnightId = 0
local pastDbId   = 0
local liveDbId   = 0

-- ── Config ───────────────────────────────────────────────────
-- ActivityWatch runs a local server on this address
local AW_HOST = "127.0.0.1:5600"

-- We discover the exact bucket name at runtime (it includes your hostname)
local AW_BUCKET = nil

-- If AW hasn't sent a new heartbeat in 25 seconds, assume browser is closed/idle
local STALE_THRESHOLD_MS = 25000

-- ── Helpers ──────────────────────────────────────────────────

-- Turns "https://www.youtube.com/watch?v=xyz" into "youtube.com"
local function extractDomain(url)
    local domain = url:match("^https?://([^/]+)") or url
    domain = domain:match("^www%.(.+)") or domain
    domain = domain:match("^([^:]+)") or domain
    return domain
end

-- Asks ActivityWatch for all its data buckets and finds the browser one.
-- AW names it "aw-watcher-web-<your hostname>" so we search by prefix.
local function discoverBucket()
    local body, status = HPR.httpGet_E(AW_HOST, "/api/0/buckets/", false)
    if status ~= 200 then
        print("[aw_parasite] cannot reach ActivityWatch (status " .. tostring(status) .. ")")
        return nil
    end

    local buckets = HPR.parseJSON_E(body)
    if not buckets then
        print("[aw_parasite] failed to parse bucket list")
        return nil
    end

    for id, _ in pairs(buckets) do
        if string.find(id, "aw-watcher-web", 1, true) then
            print("[aw_parasite] found browser bucket: " .. id)
            return id
        end
    end

    print("[aw_parasite] no browser bucket found — is aw-watcher-web extension running?")
    return nil
end

-- Fetches the most recently active browser tab from ActivityWatch.
-- Returns (url, title) or (nil, nil) if nothing is available.
local function fetchLatestUrl()
    -- discover bucket on first call
    if not AW_BUCKET then
        AW_BUCKET = discoverBucket()
        if not AW_BUCKET then return nil, nil end
    end

    local body, status = HPR.httpGet_E(AW_HOST, "/api/0/buckets/" .. AW_BUCKET .. "/events?limit=1", false)
    if status ~= 200 then
        print("[aw_parasite] events fetch failed (status " .. tostring(status) .. ")")
        return nil, nil
    end

    local events = HPR.parseJSON_E(body)
    if not events or #events == 0 then return nil, nil end

    local latest = events[1]
    local url    = latest.data and latest.data.url
    local title  = latest.data and latest.data.title

    if not url or url == "" then return nil, nil end

    return url, title or url
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

-- ── Lifecycle ────────────────────────────────────────────────

function init()
    HPR.authorName    = "Plexescor"
    HPR.extensionName = "AW URL Parasite HPR Extension"

    -- Create our table if it doesn't exist yet
    HPR.dbExecute_E([[
        create table if not exists aw_parasite_url_usage (
            url         text unique,
            title       text,
            duration_ms int
        );
    ]])

    -- Load today's saved data back into memory so we don't lose progress on restart
    local rows = HPR.dbQuery_E("select url, title, duration_ms from aw_parasite_url_usage;")
    for _, row in ipairs(rows) do
        url_history[row.url] = {
            title       = row.title,
            duration_ms = tonumber(row.duration_ms) or 0
        }
    end
    print("[aw_parasite] loaded " .. #rows .. " saved URLs from database")

    -- At midnight HPR clears the day — we clear our memory too
    midnightId = HPR.connect_E("MIDNIGHT_ROLLOVER", function()
        url_history = {}
        print("[aw_parasite] new day — history cleared")
    end)

    -- User clicked a past day in the calendar
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
            print("[aw_parasite] showing historical data (" .. #histRows .. " URLs)")
        else
            past_url_history    = {}
            is_showing_historical = false
        end
    end)

    -- User switched back to live view
    liveDbId = HPR.connect_E("LOAD_LIVE_DATA", function()
        is_showing_historical = false
    end)

    print("[aw_parasite] ready")
    return 1000  -- tick every 1000ms
end

local last_seen_url = nil
local tick_count    = 0

function onTick(delta)
    tick_count = tick_count + 1

    -- Ask ActivityWatch what tab is active right now
    local url, title = fetchLatestUrl()

    if url then
        -- URL changed → AW is actively heartbeating, reset stale timer
        if url ~= last_seen_url then
            print("[aw_parasite] active tab: " .. extractDomain(url))
            last_seen_url        = url
            time_since_last_event = 0
        else
            time_since_last_event = time_since_last_event + delta
        end

        -- Only count time if AW is actively reporting (not stale/idle)
        if time_since_last_event < STALE_THRESHOLD_MS then
            if not url_history[url] then
                url_history[url] = { title = title, duration_ms = 0 }
            end
            url_history[url].duration_ms = url_history[url].duration_ms + delta
            url_history[url].title       = title
        end
    else
        -- No URL returned — browser closed or AW not running
        time_since_last_event = time_since_last_event + delta
        last_seen_url         = nil
    end

    -- Build the list to display in the UI
    local source    = is_showing_historical and past_url_history or url_history
    local formatted = {}
    local total_ms  = 0

    for u, data in pairs(source) do
        total_ms = total_ms + data.duration_ms
        table.insert(formatted, {
            url        = extractDomain(u),
            title      = extractDomain(u),
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

    -- Save to database every 10 seconds
    time_since_last_flush = time_since_last_flush + delta
    if time_since_last_flush >= 10000 then
        local ok, err = pcall(flushToDatabase)
        if not ok then print("[aw_parasite] flush error: " .. tostring(err)) end
        time_since_last_flush = 0
    end
end

function onExit()
    -- Final save before shutdown
    flushToDatabase()

    -- Always disconnect events to prevent memory leaks
    HPR.disconnect_E("MIDNIGHT_ROLLOVER", midnightId)
    HPR.disconnect_E("LOAD_DATABASE_SINGULAR", pastDbId)
    HPR.disconnect_E("LOAD_LIVE_DATA", liveDbId)

    print("[aw_parasite] shutdown clean")
end
