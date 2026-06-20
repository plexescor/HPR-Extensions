HPR.authorName = "Plexescor"
HPR.extensionName = "Budget Doom"

-- Resolution (Low-res for pixelated look and high performance)
local width = 160
local height = 120

local hudVisible = true   -- HUD shown by default
local killCount = 0

-- Map definition (32x32 grid: 0 = empty, 1..4 = wall textures)
local mapWidth = 32
local mapHeight = 32
local map = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,2,2,0,0,1,0,3,3,3,3,0,4,0,1,0,3,3,3,3,3,3,0,4,4,4,4,4,4,0,1},
    {1,0,2,0,0,0,0,0,3,0,0,3,0,4,0,0,0,3,0,0,0,0,3,0,4,0,0,0,0,4,0,1},
    {1,0,2,0,0,0,1,0,3,0,0,3,0,4,0,1,0,3,0,2,2,0,3,0,4,0,2,2,0,4,0,1},
    {1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,2,2,0,0,0,0,0,2,2,0,0,0,1},
    {1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1},
    {1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1},
    {1,0,4,0,0,0,1,0,2,2,2,2,0,3,0,1,0,4,4,4,4,4,0,1,0,3,3,3,3,3,0,1},
    {1,0,4,0,0,0,0,0,2,0,0,2,0,3,0,0,0,4,0,0,0,4,0,0,0,3,0,0,0,3,0,1},
    {1,0,4,4,0,0,1,0,2,2,2,2,0,3,0,1,0,4,0,0,0,4,0,1,0,3,0,0,0,3,0,1},
    {1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,1},
    {1,0,2,2,2,2,2,2,0,1,0,1,0,3,3,3,3,3,3,3,3,3,3,3,0,0,1,0,1,0,0,1},
    {1,0,2,0,0,0,0,2,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,1},
    {1,0,2,0,4,4,0,2,0,1,0,1,0,3,0,4,4,4,4,4,4,0,0,3,0,0,1,0,1,0,0,1},
    {1,0,2,0,4,4,0,2,0,1,0,1,0,3,0,4,0,0,0,0,4,0,0,3,0,0,1,0,1,0,0,1},
    {1,0,2,0,0,0,0,2,0,1,0,1,0,3,0,4,0,1,1,0,4,0,0,3,0,0,1,0,1,0,0,1},
    {1,0,2,2,2,2,2,2,0,1,0,1,0,3,0,4,0,1,1,0,4,0,0,3,0,0,1,0,1,0,0,1},
    {1,0,0,0,0,0,0,0,0,1,0,1,0,3,0,4,0,0,0,0,4,0,0,3,0,0,1,0,1,0,0,1},
    {1,1,1,1,0,1,1,1,1,1,0,1,0,3,3,3,3,3,0,3,3,3,3,3,0,0,1,0,1,1,1,1},
    {1,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1},
    {1,0,0,1,0,1,0,4,4,4,0,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,0,1},
    {1,0,0,0,0,0,0,4,0,4,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,1,0,1},
    {1,0,0,1,0,1,0,4,4,4,0,1,1,1,1,0,1,0,1,0,2,2,2,2,2,2,2,2,0,1,0,1},
    {1,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,2,0,0,0,1},
    {1,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,1,0,1,0,2,0,0,0,0,0,0,2,0,1,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
}

-- Player State
local posX = 3.5
local posY = 3.5
local dirX = 1.0
local dirY = 0.0
local planeX = 0.0
local planeY = 0.66
local moveSpeed = 0.12
local rotSpeed = 0.08

-- Input State
local keysHeld = {}
local keysPressedThisFrame = {}

-- Shading / Fog constants
local fogDensity = 0.18

-- Procedural Wall Textures (32x32)
local textures = {}
local texSize = 32

-- Shotgun HUD Sprite (48x32)
local weapon_frames = {}
local weapon_width = 48
local weapon_height = 32
local shootCooldown = 0

-- Enemy Sprite Data structures (16x16)
local enemy_width = 16
local enemy_height = 16
local enemy_sprites = {}
local enemies = {}

local raw_enemies = {
  -- Sprite 1: Fodder Demon (3 HP) - Red
  [=[
................
...kkkk..kkkk...
..krrmkkkkmrry..
.krmrrmkkrrmrrmk
.krmmmmmmmmmmmmk
.kmmwmmwmmwmmwmk
.kmmwmmwmmwmmwmk
..kmmmmmmmmmmmk.
...kkkkkkkkkkk..
....kwwwwwwk....
....kwwwwwwk....
.....kkkkkk.....
......kkkk......
.......kk.......
................
................
]=],
  -- Sprite 2: Heavy Demon (10 HP) - Green
  [=[
................
....kkkkkkkk....
...kuugkkuugk...
..kuugggguguugk.
.kugguuuuuguuggk
.kuguuywkywuuguk
.kuguuywkywuuguk
..kuugwwkkwwguk.
...kuugggguguk..
....kuuuuuuuk...
.....kuuguuk....
......kkkk......
................
................
................
................
]=]
}

local raw_frames = {
  -- Frame 1: Idle
  [=[
................................................
................................................
................................................
................................................
................................................
................................................
................................................
.....................kkk..kkk...................
....................kggwkkwwgk..................
...................kgggdwkwdggk.................
...................kgggdwkwdggk.................
...................kgggdwkwdggk.................
..................kggggdkkdkgggk................
..................kggggdkkdkgggk................
..................kggggdkkdkgggk................
.................kgggggdkkdkggggk...............
.................kgggggdkkdkggggk...............
.................kgggggdkkdkggggk...............
................kggggggdkkdkgggggk..............
................kggddggdkkdkggddgk..............
...............kggdssdggkkggdssdgk..............
..............kgooosssogkkgoosssogk.............
.............kgoohhhoosogkgoohhhoogk............
.............koohhhhhoosogooohhhhhoog...........
............koohhhhhhhoosooohhhhhhhoog..........
...........koohhhhhhhhoosooohhhhhhhhoog.........
..........koosssssssssoosooossssssssoog.........
.........koossssssssssoosooossssssssssoog.......
........koosssssssssssoosooosssssssssssoog......
.......koossssssssssssoosooossssssssssssoog.....
................................................
................................................
]=],
  -- Frame 2: Firing (Muzzle Flash)
  [=[
................................................
...................rryyyyyyrr...................
.................rryyyyyyyyyyrr.................
...............rryyfffffffffyyrr................
..............ryyffffrrrrrrrrffyyr..............
.............ryffrrkkkkkkkkkkrrffyr.............
............ryfrrkkkkk..kkkkkrrrfyyr............
...........krffrkkkkgkkggkgggkrffrkkk...........
...........kggwkkwwgkkwwgkkwwgkkwwgk............
...................kgggdwkwdggk.................
...................kgggdwkwdggk.................
...................kgggdwkwdggk.................
..................kggggdkkdkgggk................
..................kggggdkkdkgggk................
..................kggggdkkdkgggk................
.................kgggggdkkdkggggk...............
.................kgggggdkkdkggggk...............
.................kgggggdkkdkggggk...............
................kggggggdkkdkgggggk..............
................kggddggdkkdkggddgk..............
...............kggdssdggkkggdssdgk..............
..............kgooosssogkkgoosssogk.............
.............kgoohhhoosogkgoohhhoogk............
.............koohhhhhoosogooohhhhhoog...........
............koohhhhhhhoosooohhhhhhhoog..........
...........koohhhhhhhhoosooohhhhhhhhoog.........
..........koosssssssssoosooossssssssoog.........
.........koossssssssssoosooossssssssssoog.......
........koosssssssssssoosooosssssssssssoog......
.......koossssssssssssoosooossssssssssssoog.....
................................................
................................................
]=]
}

local function generateTextures()
    -- Texture 1: Red Brick
    textures[1] = {}
    for y = 0, texSize - 1 do
        for x = 0, texSize - 1 do
            if y % 8 == 0 or (y % 8 < 8 and x % 16 == 0 and math.floor(y / 8) % 2 == 0) 
               or (y % 8 < 8 and (x + 8) % 16 == 0 and math.floor(y / 8) % 2 == 1) then
                textures[1][y * texSize + x] = {35, 35, 35} -- Mortar lines
            else
                textures[1][y * texSize + x] = {140 - (y % 8) * 4, 30, 20} -- Red bricks
            end
        end
    end

    -- Texture 2: Blue Grid
    textures[2] = {}
    for y = 0, texSize - 1 do
        for x = 0, texSize - 1 do
            if x == 0 or x == texSize - 1 or y == 0 or y == texSize - 1 or x == y or x == texSize - 1 - y then
                textures[2][y * texSize + x] = {0, 110, 240} -- Neon Blue
            else
                textures[2][y * texSize + x] = {10, 20, 50} -- Dark grid base
            end
        end
    end

    -- Texture 3: Wood Panel
    textures[3] = {}
    for y = 0, texSize - 1 do
        for x = 0, texSize - 1 do
            if x % 8 == 0 then
                textures[3][y * texSize + x] = {35, 18, 8} -- Timber line
            else
                textures[3][y * texSize + x] = {90 + (x % 8) * 5, 55 + (x % 8) * 2, 20} -- Wood grain
            end
        end
    end

    -- Texture 4: Stone
    textures[4] = {}
    for y = 0, texSize - 1 do
        for x = 0, texSize - 1 do
            local noise = (x * 7 + y * 13) % 25
            textures[4][y * texSize + x] = {70 + noise, 70 + noise, 75 + noise} -- Gray stone block
        end
    end
end

local function parseWeaponFrames()
    local color_map = {
        ["."] = nil, -- transparent
        ["k"] = {10, 10, 10, 255}, -- black outline
        ["g"] = {110, 110, 120, 255}, -- dark gray metal
        ["w"] = {200, 200, 205, 255}, -- silver metal highlight
        ["d"] = {60, 60, 65, 255}, -- shadow metal
        ["o"] = {90, 50, 20, 255}, -- brown wood stock
        ["h"] = {140, 90, 40, 255}, -- wood highlight
        ["s"] = {55, 30, 12, 255}, -- wood shadow
        ["r"] = {255, 50, 0, 255}, -- muzzle flash red
        ["f"] = {255, 120, 0, 255}, -- muzzle flash orange
        ["y"] = {255, 230, 80, 255} -- muzzle flash yellow
    }
    
    for fIdx, raw in ipairs(raw_frames) do
        local pixels = {}
        local y = 1
        for line in raw:gmatch("[^\r\n]+") do
            if y <= weapon_height then
                for x = 1, weapon_width do
                    local char = line:sub(x, x)
                    local color = color_map[char]
                    pixels[(y - 1) * weapon_width + x] = color
                end
                y = y + 1
            end
        end
        weapon_frames[fIdx] = pixels
    end
end

local function parseEnemySprites()
    local color_map = {
        ["."] = nil, -- transparent
        ["k"] = {10, 10, 10, 255}, -- black outline
        ["r"] = {220, 20, 20, 255}, -- demon red
        ["m"] = {120, 10, 10, 255}, -- demon maroon
        ["g"] = {20, 200, 20, 255}, -- heavy green
        ["u"] = {10, 110, 10, 255}, -- heavy dark green
        ["y"] = {255, 230, 30, 255}, -- yellow eyes
        ["w"] = {255, 255, 255, 255} -- white teeth/pupils
    }

    for idx, raw in ipairs(raw_enemies) do
        local pixels = {}
        local y = 1
        for line in raw:gmatch("[^\r\n]+") do
            if y <= enemy_height then
                for x = 1, enemy_width do
                    local char = line:sub(x, x)
                    local color = color_map[char]
                    pixels[(y - 1) * enemy_width + x] = color
                end
                y = y + 1
            end
        end
        enemy_sprites[idx] = pixels
    end
end

local FONT = {
  ["0"]={"111","101","101","101","111"}, ["1"]={"010","110","010","010","111"},
  ["2"]={"111","001","111","100","111"}, ["3"]={"111","001","111","001","111"},
  ["4"]={"101","101","111","001","001"}, ["5"]={"111","100","111","001","111"},
  ["6"]={"111","100","111","101","111"}, ["7"]={"111","001","010","010","010"},
  ["8"]={"111","101","111","101","111"}, ["9"]={"111","101","111","001","111"},
  ["A"]={"111","101","111","101","101"}, ["C"]={"111","100","100","100","111"},
  ["D"]={"110","101","101","101","110"}, ["E"]={"111","100","111","100","111"},
  ["H"]={"101","101","111","101","101"}, ["I"]={"111","010","010","010","111"},
  ["K"]={"101","101","110","101","101"}, ["L"]={"100","100","100","100","111"},
  ["M"]={"101","111","111","101","101"}, ["O"]={"111","101","101","101","111"},
  ["P"]={"111","101","111","100","100"}, ["R"]={"111","101","111","110","101"},
  ["S"]={"111","100","111","001","111"}, ["T"]={"111","010","010","010","010"},
  ["U"]={"101","101","101","101","111"}, ["V"]={"101","101","101","101","010"}, 
  ["W"]={"101","101","111","111","101"},
  [":"]={"000","010","000","010","000"}, ["-"]={"000","000","111","000","000"},
  [" "]={"000","000","000","000","000"},
}
local function drawChar(pixels, char, px, py, color, scale)
    scale = scale or 1
    local glyph = FONT[char]
    if not glyph then return end
    for row = 1, 5 do
        local line = glyph[row]
        for col = 1, 3 do
            if line:sub(col, col) == "1" then
                for sy = 0, scale - 1 do
                    for sx = 0, scale - 1 do
                        local screenX = px + (col - 1) * scale + sx
                        local screenY = py + (row - 1) * scale + sy
                        if screenX >= 0 and screenX < width and screenY >= 0 and screenY < height then
                            local idx = screenY * width + screenX + 1
                            pixels[idx] = string.char(color[1], color[2], color[3], 255)
                        end
                    end
                end
            end
        end
    end
end

local function drawText(pixels, text, px, py, color, scale)
    scale = scale or 1
    local cursorX = px
    for i = 1, #text do
        drawChar(pixels, text:sub(i, i):upper(), cursorX, py, color, scale)
        cursorX = cursorX + (3 * scale + 1)
    end
end

local function spawnEnemy(typeIdx)
    local tries = 0
    while tries < 100 do
        local rx = math.random() * (mapWidth - 2) + 1.5
        local ry = math.random() * (mapHeight - 2) + 1.5
        local mx = math.floor(rx) + 1
        local my = math.floor(ry) + 1

        if map[my] and map[my][mx] == 0 then
            local dx = rx - posX
            local dy = ry - posY
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 4.0 then
                local hp = (typeIdx == 1) and 3 or 10
                local speed = 0.6 * moveSpeed
                table.insert(enemies, {
                    x = rx, y = ry, type = typeIdx,
                    hp = hp, maxHp = hp, speed = speed, dead = false
                })
                return true
            end
        end
        tries = tries + 1
    end

    -- Fallback: drop the distance requirement, just find ANY empty tile.
    -- Guarantees a spawn instead of silently giving up.
    tries = 0
    while tries < 300 do
        local rx = math.random() * (mapWidth - 2) + 1.5
        local ry = math.random() * (mapHeight - 2) + 1.5
        local mx = math.floor(rx) + 1
        local my = math.floor(ry) + 1

        if map[my] and map[my][mx] == 0 then
            local hp = (typeIdx == 1) and 3 or 10
            local speed = 0.6 * moveSpeed
            table.insert(enemies, {
                x = rx, y = ry, type = typeIdx,
                hp = hp, maxHp = hp, speed = speed, dead = false
            })
            return true
        end
        tries = tries + 1
    end

    -- Truly should never reach here on a normal map, but log it if it does
    HPR.log_E("DoomRaycaster", "Failed to spawn enemy type " .. typeIdx .. " — map may be too dense")
    return false
end

local function restartGame()
    posX = 3.5
    posY = 3.5
    dirX = 1.0
    dirY = 0.0
    planeX = 0.0
    planeY = 0.66
    shootCooldown = 0
    killCount = 0
    enemies = {}
    for i = 1, 6 do spawnEnemy(1) end
    for i = 1, 4 do spawnEnemy(2) end
end

function init()
    HPR.log_E("DoomRaycaster", "Loading DOOM raycaster extension...")
    pcall(function() math.randomseed(os.time()) end)

    generateTextures()
    parseWeaponFrames()
    parseEnemySprites()

    -- Spawn initial enemies: 6 of Type 1 (fodder, 3hp), 4 of Type 2 (heavy, 10hp)
    for i = 1, 6 do spawnEnemy(1) end
    for i = 1, 4 do spawnEnemy(2) end

    -- Connect keyboard inputs
    HPR.connect_E("MISC_KEY_PRESSED", function(key)
        if not keysHeld[key] then
            keysPressedThisFrame[key] = true
        end
        keysHeld[key] = true
    end)

    HPR.connect_E("MISC_KEY_RELEASED", function(key)
        keysHeld[key] = nil
    end)

    return 20 -- Tick rate (~50 FPS rendering, runs extremely fast and responsive)
end

function onTick(delta)
    local speedMultiplier = delta / 60.0
    -- Detect movement based on held state
    local isUp = keysHeld["w"] or keysHeld["up"]
    local isDown = keysHeld["s"] or keysHeld["down"]
    local isLeft = keysHeld["a"] or keysHeld["left"]
    local isRight = keysHeld["d"] or keysHeld["right"]
    local isSpace = keysPressedThisFrame[" "] or keysPressedThisFrame["space"]
    local isRestart = keysPressedThisFrame["r"]
    local isToggleHud = keysPressedThisFrame["c"]

    if isRestart then
        restartGame()
    end

    if isToggleHud then
        hudVisible = not hudVisible
    end

    -- Process movement and rotation
    local move = 0
    local rot = 0
    if isUp then move = 1 elseif isDown then move = -1 end
    if isLeft then rot = -1 elseif isRight then rot = 1 end

    if rot ~= 0 then
        local angle = rot * rotSpeed * speedMultiplier
        local oldDirX = dirX
        dirX = dirX * math.cos(angle) - dirY * math.sin(angle)
        dirY = oldDirX * math.sin(angle) + dirY * math.cos(angle)
        
        local oldPlaneX = planeX
        planeX = planeX * math.cos(angle) - planeY * math.sin(angle)
        planeY = oldPlaneX * math.sin(angle) + planeY * math.cos(angle)
    end

    if move ~= 0 then
        local newX = posX + move * dirX * moveSpeed * speedMultiplier
        local newY = posY + move * dirY * moveSpeed * speedMultiplier
        
        -- Fully safe map indexing range bounds checks
        local checkX = math.floor(newX + 0.1 * move * dirX) + 1
        local checkY = math.floor(newY + 0.1 * move * dirY) + 1
        local currX = math.floor(posX) + 1
        local currY = math.floor(posY) + 1
        
        if checkX >= 1 and checkX <= mapWidth and currY >= 1 and currY <= mapHeight then
            if map[currY] and map[currY][checkX] == 0 then
                posX = newX
            end
        end
        if currX >= 1 and currX <= mapWidth and checkY >= 1 and checkY <= mapHeight then
            if map[checkY] and map[checkY][currX] == 0 then
                posY = newY
            end
        end
    end

    -- Process enemy movement towards player
    for idx, enemy in ipairs(enemies) do
        if not enemy.dead then
            local dx = posX - enemy.x
            local dy = posY - enemy.y
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist > 0.4 then
                local dirX_enemy = dx / dist
                local dirY_enemy = dy / dist
                local moveX = dirX_enemy * enemy.speed * speedMultiplier
                local moveY = dirY_enemy * enemy.speed * speedMultiplier
                
                local newX = enemy.x + moveX
                local newY = enemy.y + moveY
                
                local checkX = math.floor(newX) + 1
                local checkY = math.floor(newY) + 1
                local currX = math.floor(enemy.x) + 1
                local currY = math.floor(enemy.y) + 1
                
                if checkX >= 1 and checkX <= mapWidth and currY >= 1 and currY <= mapHeight then
                    if map[currY] and map[currY][checkX] == 0 then
                        enemy.x = newX
                    end
                end
                if currX >= 1 and currX <= mapWidth and checkY >= 1 and checkY <= mapHeight then
                    if map[checkY] and map[checkY][currX] == 0 then
                        enemy.y = newY
                    end
                end
            end
        end
    end

    -- Process weapon firing logic (cooldown decrement)
    if isSpace and shootCooldown <= 0 then
        shootCooldown = 3 -- 3 frames muzzle flash
    end

    local currentWeaponFrame = 1
    if shootCooldown > 0 then
        shootCooldown = shootCooldown - 1
        if shootCooldown >= 1 then
            currentWeaponFrame = 2 -- Firing Frame
        else
            currentWeaponFrame = 1
        end
    end

    -- Raycasting & Render loop
    local pixels = {}
    local zBuffer = {} -- Wall distance Z-buffer
    
    for x = 0, width - 1 do
        local cameraX = 2 * x / width - 1
        local rayDirX = dirX + planeX * cameraX
        local rayDirY = dirY + planeY * cameraX

        local mapX = math.floor(posX)
        local mapY = math.floor(posY)

        local deltaDistX = (rayDirX == 0) and 1e30 or math.abs(1 / rayDirX)
        local deltaDistY = (rayDirY == 0) and 1e30 or math.abs(1 / rayDirY)
        local perpWallDist

        local stepX, stepY
        local sideDistX, sideDistY

        if rayDirX < 0 then
            stepX = -1
            sideDistX = (posX - mapX) * deltaDistX
        else
            stepX = 1
            sideDistX = (mapX + 1.0 - posX) * deltaDistX
        end
        if rayDirY < 0 then
            stepY = -1
            sideDistY = (posY - mapY) * deltaDistY
        else
            stepY = 1
            sideDistY = (mapY + 1.0 - posY) * deltaDistY
        end

        -- Perform DDA
        local hit = 0
        local side = 0
        while hit == 0 do
            if sideDistX < sideDistY then
                sideDistX = sideDistX + deltaDistX
                mapX = mapX + stepX
                side = 0
            else
                sideDistY = sideDistY + deltaDistY
                mapY = mapY + stepY
                side = 1
            end
            
            -- Guard DDA loop coordinates bounds
            if mapX < 0 or mapX >= mapWidth or mapY < 0 or mapY >= mapHeight then
                hit = 1
                break
            end
            
            if map[mapY + 1] and map[mapY + 1][mapX + 1] and map[mapY + 1][mapX + 1] > 0 then
                hit = 1
            end
        end

        if side == 0 then
            perpWallDist = sideDistX - deltaDistX
        else
            perpWallDist = sideDistY - deltaDistY
        end
        if perpWallDist <= 0 then perpWallDist = 0.01 end

        -- Save wall distance to Z-buffer
        zBuffer[x + 1] = perpWallDist

        local lineHeight = math.floor(height / perpWallDist)
        if lineHeight < 1 then lineHeight = 1 end

        -- Calculate drawing coordinates
        local drawStart = math.floor(-lineHeight / 2 + height / 2)
        local drawEnd = math.floor(lineHeight / 2 + height / 2)

        if drawStart < 0 then drawStart = 0 end
        if drawEnd >= height then drawEnd = height - 1 end

        -- Texture parameters
        local texNum = (map[mapY + 1] and map[mapY + 1][mapX + 1]) or 1
        local wallX
        if side == 0 then
            wallX = posY + perpWallDist * rayDirY
        else
            wallX = posX + perpWallDist * rayDirX
        end
        wallX = wallX - math.floor(wallX)

        local texX = math.floor(wallX * texSize)
        if side == 0 and rayDirX > 0 then texX = texSize - texX - 1 end
        if side == 1 and rayDirY < 0 then texX = texSize - texX - 1 end
        if texX < 0 then texX = 0 elseif texX >= texSize then texX = texSize - 1 end

        -- Calculate distance fog/shading
        local shade = 1.0 / (1.0 + perpWallDist * fogDensity)
        if side == 1 then shade = shade * 0.75 end

        -- Render the column vertical slice
        for y = 0, height - 1 do
            local idx = y * width + x + 1
            if y < drawStart then
                -- Ceiling
                pixels[idx] = string.char(25, 25, 25, 255)
            elseif y > drawEnd then
                -- Floor
                pixels[idx] = string.char(40, 40, 40, 255)
            else
                -- Wall texture pixel
                local d = y * 256 - height * 128 + lineHeight * 128
                local texY = math.floor((d * texSize) / lineHeight / 256)
                if texY < 0 then texY = 0 elseif texY >= texSize then texY = texSize - 1 end

                local texColor = (textures[texNum] and textures[texNum][texY * texSize + texX]) or {128, 128, 128}
                local r = math.max(5, math.floor((texColor[1] or 128) * (shade or 1.0)))
                local g = math.max(5, math.floor((texColor[2] or 128) * (shade or 1.0)))
                local b = math.max(5, math.floor((texColor[3] or 128) * (shade or 1.0)))
                pixels[idx] = string.char(r, g, b, 255)
            end
        end
    end

    -- Process hit detection when firing (using the fully populated zBuffer)
    if isSpace and shootCooldown == 2 then -- Trigger exactly on the first firing tick
        local hitEnemy = nil
        local minTransY = 1e9
        local centerCol = math.floor(width / 2) -- Center column (index 80)

        for idx, enemy in ipairs(enemies) do
            if not enemy.dead then
                local spriteX = enemy.x - posX
                local spriteY = enemy.y - posY

                local invDet = 1.0 / (planeX * dirY - dirX * planeY)
                local transformX = invDet * (dirY * spriteX - dirX * spriteY)
                local transformY = invDet * (-planeY * spriteX + planeX * spriteY)

                if transformY > 0.1 then
                local spriteScreenX = math.floor((width / 2) * (1 + transformX / transformY))
                local spriteWidth = math.abs(math.floor(height / transformY))
                if enemy.type == 2 then
                    spriteWidth = spriteWidth * 2.0
                end
                
                local halfWidth = (spriteWidth / 2) * 1.3
                if math.abs(centerCol - spriteScreenX) <= halfWidth then
                        if transformY < zBuffer[centerCol + 1] then
                            if transformY < minTransY then
                                minTransY = transformY
                                hitEnemy = enemy
                            end
                        end
                    end
                end
            end
        end

        if hitEnemy then
            hitEnemy.hp = hitEnemy.hp - 1
            if hitEnemy.hp <= 0 then
                hitEnemy.dead = true
                killCount = killCount + 1
                -- Spawn replacement enemy of same type
                local t = hitEnemy.type
                for i, e in ipairs(enemies) do
                    if e == hitEnemy then
                        table.remove(enemies, i)
                        break
                    end
                end
                spawnEnemy(t)
            end
        end
    end

    -- Sort and render billboard sprites (enemies)
    local spriteOrder = {}
    for i = 1, #enemies do
        local dx = enemies[i].x - posX
        local dy = enemies[i].y - posY
        enemies[i].dist = dx*dx + dy*dy
        spriteOrder[i] = i
    end
    table.sort(spriteOrder, function(a, b)
        return (enemies[a].dist or 0) > (enemies[b].dist or 0)
    end)

    for i = 1, #spriteOrder do
        local enemy = enemies[spriteOrder[i]]
        if not enemy.dead then
            local spriteX = enemy.x - posX
            local spriteY = enemy.y - posY

            local invDet = 1.0 / (planeX * dirY - dirX * planeY)
            local transformX = invDet * (dirY * spriteX - dirX * spriteY)
            local transformY = invDet * (-planeY * spriteX + planeX * spriteY)

            if transformY > 0.1 then
                local spriteScreenX = math.floor((width / 2) * (1 + transformX / transformY))
                local spriteHeight = math.abs(math.floor(height / transformY))
                if enemy.type == 2 then
                    spriteHeight = spriteHeight * 2.0
                end
                if spriteHeight > height * 2 then spriteHeight = height * 2 end

                local drawStartY = math.floor(-spriteHeight / 2 + height / 2)
                if drawStartY < 0 then drawStartY = 0 end
                local drawEndY = math.floor(spriteHeight / 2 + height / 2)
                if drawEndY >= height then drawEndY = height - 1 end

                local spriteWidth = math.abs(math.floor(height / transformY))
                if enemy.type == 2 then
                    spriteWidth = spriteWidth * 2.0
                end
                local drawStartX = math.floor(-spriteWidth / 2 + spriteScreenX)
                local drawEndX = math.floor(spriteWidth / 2 + spriteScreenX)

                local clipStartX = drawStartX < 0 and 0 or drawStartX
                local clipEndX = drawEndX >= width and width - 1 or drawEndX

                local shade = 1.0 / (1.0 + transformY * fogDensity)

                for stripe = clipStartX, clipEndX do
                    local texX = math.floor((stripe - drawStartX) * enemy_width / spriteWidth) + 1
                    if texX >= 1 and texX <= enemy_width then
                        if transformY < zBuffer[stripe + 1] then
                            local pixels_sprite = (enemy.type == 1) and enemy_sprites[1] or enemy_sprites[2]
                            for y = drawStartY, drawEndY do
                                local texY = math.floor((y - drawStartY) * enemy_height / spriteHeight) + 1
                                if texY >= 1 and texY <= enemy_height then
                                    local color = pixels_sprite[(texY - 1) * enemy_width + texX]
                                    if color then
                                        local idx = y * width + stripe + 1
                                        local r = math.max(5, math.floor(color[1] * shade))
                                        local g = math.max(5, math.floor(color[2] * shade))
                                        local b = math.max(5, math.floor(color[3] * shade))
                                        pixels[idx] = string.char(r, g, b, 255)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Overlay Shotgun sprite centered at the bottom
    local startX = math.floor((width - weapon_width) / 2)
    local startY = height - weapon_height
    local wFrame = weapon_frames[currentWeaponFrame] or weapon_frames[1]

    for y = 0, weapon_height - 1 do
        for x = 0, weapon_width - 1 do
            local color = wFrame[y * weapon_width + x + 1]
            if color then
                local screenX = startX + x
                local screenY = startY + y
                if screenX >= 0 and screenX < width and screenY >= 0 and screenY < height then
                    local idx = screenY * width + screenX + 1
                    pixels[idx] = string.char(color[1], color[2], color[3], color[4])
                end
            end
        end
    end

    -- Kill counter, top-left
    drawText(pixels, "KILLS:" .. tostring(killCount), 2, 2, {255, 255, 255}, 1)

    if hudVisible then
        

        -- Controls, top-right, right-aligned, one control per line
        local rightLines = {
            "WASD:MOVE",
            "SPACE:SHOOT",
            "R:RESTART",
            "C:HIDE HUD",
        }
        local lineY = 2
        for _, line in ipairs(rightLines) do
            local lineWidth = #line * 4 - 1
            local startXLine = width - lineWidth - 2
            drawText(pixels, line, startXLine, lineY, {255, 255, 0}, 1)
            lineY = lineY + 7
        end
    end


    -- Construct and send final buffer
    local buffer = table.concat(pixels)
    HPR.setUiImage_E("miscImage_S", width, height, buffer)

    -- Clear transient pressed state at the end of the tick
    for k in pairs(keysPressedThisFrame) do
        keysPressedThisFrame[k] = nil
    end
end

function onExit()
    HPR.log_E("DoomRaycaster", "DOOM raycaster extension stopped!")
end
