-- ============================================================
--  AW AFK Parasite HPR Extension
--  Author: Plexescor
--
--  What this does:
--  Starts an HTTP server on port 5600 (ActivityWatch default).
--  Receives heartbeat telemetry from aw-watcher-afk directly,
--  and calls HPR.stopTracking_E / HPR.startTracking_E based
--  on the user's AFK status.
--
--  Requirement:
--  Point your aw-watcher-afk at HPR (localhost:5600) and it
--  will control tracking without running the real ActivityWatch!
-- ============================================================

local is_afk = false

local function handleAfkStatus(status)
    local afk_now = (status == "afk" or status == "hibernating")

    if afk_now then
        if not is_afk then
            is_afk = true
            print("[aw_afk] user is AFK/hibernating — stopping tracking")
            local ok, err = pcall(HPR.stopTracking_E)
            if not ok then print("[aw_afk] stopTracking_E error: " .. tostring(err)) end
        end
    else
        if is_afk then
            is_afk = false
            print("[aw_afk] user returned — resuming tracking")
            local ok, err = pcall(HPR.startTracking_E)
            if not ok then print("[aw_afk] startTracking_E error: " .. tostring(err)) end
        end
    end
end

function init()
    HPR.authorName    = "Plexescor"
    HPR.extensionName = "AW AFK Parasite HPR Extension"

    print("[aw_afk] starting HTTP server on 127.0.0.1:5600...")
    local ok = HPR.startServer_E(5600, function(req)

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

        if req.method == "GET" and string.find(req.path, "/api/0/buckets") then
            local bucket_id = "aw-watcher-afk-mock"
            return {
                status = 200,
                headers = {
                    ["Content-Type"]                = "application/json",
                    ["Access-Control-Allow-Origin"] = "*"
                },
                body = HPR.toJSON_E({
                    [bucket_id] = {
                        id       = bucket_id,
                        created  = "2026-05-29T12:00:00Z",
                        name     = "AFK Watcher",
                        type     = "afkstatus",
                        client   = "aw-watcher-afk",
                        hostname = "localhost"
                    }
                })
            }
        end

        if req.method == "POST" and string.find(req.path, "/api/0/buckets/") and not string.find(req.path, "/heartbeat") then
            local bucket_info = HPR.parseJSON_E(req.body) or {}
            bucket_info.id      = req.path:match("/api/0/buckets/([^/]+)") or "aw-watcher-afk-mock"
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

        if req.method == "POST" and string.find(req.path, "/heartbeat") then
            local event = HPR.parseJSON_E(req.body)
            if event and event.data then
                handleAfkStatus(event.data.status)
                event.id = 12345
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

        return {
            status = 404,
            headers = { ["Access-Control-Allow-Origin"] = "*" },
            body = "Endpoint Not Found"
        }
    end)

    if ok then
        print("[aw_afk] server listening successfully on port 5600!")
    else
        print("[aw_afk] FAILED to start HTTP server. Check if port 5600 is already in use!")
    end

    return 1000
end

function onTick(delta) end

function onExit()
    print("[aw_afk] server stopped cleanly")
end