# Budget Doom
<img width="1331" height="951" alt="Screenshot 2026-06-20 210815" src="https://github.com/user-attachments/assets/b4282f8a-6f1c-49e1-8f07-d5fa0819be80" />

A fully self-contained, software-rendered raycasted FPS that runs entirely inside HPR's miscellaneous image panel. No external engine, no game framework, no GPU — every frame is built pixel-by-pixel in pure Lua and pushed to the UI as a raw RGBA buffer.

Author: Plexescor

<img width="1331" height="951" alt="Screenshot 2026-06-20 210753" src="https://github.com/user-attachments/assets/ff3ba111-bbab-4807-9af2-b72c4b56c841" />


---

## Requirements

**None.** This extension does not read your activity data, does not touch the database, does not make any network calls, and does not depend on any other extension.

The only thing you need to do is enable the panel it renders into:

1. Open HPR.
2. Go to **UI Settings**.
3. Enable **"Show miscellaneous image panel"**.
4. Hit RESCAN in extensions panel

That's it. If the panel isn't enabled, the extension still runs in the background — it just has nowhere to draw, so you won't see anything.

---

## Installation

1. Copy `doom.lua` into your HPR extensions folder:

   **Linux:**
    ~/.config/HPR/extensions/
   **Windows:**
    %APPDATA%\HPR\HPR_Config\extensions\

You can place it directly or inside a subfolder, e.g. `extensions/budget-doom/doom.lua` — HPR scans recursively.

2. Enable **"Show miscellaneous image panel"** in HPR's UI Settings (see above).

3. Hit RESCAN in extensions panel

4. Click into the miscellaneous image panel and start playing.

---

## Controls

| Key | Action |
|---|---|
| `W` / `Up` | Move forward |
| `S` / `Down` | Move backward |
| `A` / `Left` | Turn left |
| `D` / `Right` | Turn right |
| `Space` | Fire shotgun |
| `R` | Restart game (resets position, kill count, and enemies) |
| `C` | Toggle the on-screen control list |

The kill counter (top-left) is always visible and is not affected by `C`. The control list (top-right) toggles with `C`; while hidden, a small `C:SHOW` hint remains in its place so the toggle is never lost. While visible, it reads `C:HIDE`.

---

## How it works

Everything in this extension happens inside two functions HPR calls on a lifecycle hook: `init()` (once, at load) and `onTick(delta)` (repeatedly, at the tick rate `init()` returns).

### Rendering pipeline

- **Resolution**: Internally renders at 160×120 for performance and a deliberately retro/pixelated look. HPR's image panel scales this up for display.
- **Raycasting**: Classic DDA (Digital Differential Analysis) raycasting, one ray cast per horizontal pixel column (160 rays per frame). This is the same core algorithm used in 1992-era Wolfenstein 3D / early DOOM-style engines — walls are solid vertical line segments computed from ray-to-grid intersections, not true 3D geometry.
- **Map**: A hardcoded 32×32 grid. `0` = walkable floor, `1`–`4` = wall tiles, each mapped to a different procedurally generated 32×32 texture (brick, neon grid, wood panel, stone) computed once at load time — no image files are loaded or required.
- **Sprites**: Enemies and the weapon HUD are stored as hand-authored ASCII art (`raw_enemies`, `raw_frames`) and parsed into RGBA pixel arrays at load time via a character-to-color lookup table. Enemy sprites are billboarded (always face the camera) and depth-sorted back-to-front before rendering, with a per-column Z-buffer check against wall distance so sprites correctly hide behind walls.
- **Text/HUD**: There is no font system in HPR's image panel, so all on-screen text (kill counter, control hints) is rendered using a custom embedded 3×5 bitmap font, drawn pixel-by-pixel directly into the same buffer as the 3D scene.
- **Output**: Every tick, the full 160×120 RGBA pixel buffer is flattened into a single byte string and pushed via `HPR.setUiImage_E("miscImage_S", width, height, buffer)`.

### Gameplay loop

- **Enemies**: Two types — a 3 HP "fodder" demon and a 10 HP "heavy" demon. The game spawns 6 fodder + 4 heavy on start.
- **Spawning**: New enemies pick a random walkable tile that's both empty on the map grid and more than 4 units from the player, retried up to 100 times. If that fails (rare, only on very cramped maps), a fallback pass drops the distance requirement and just finds any open tile, so spawning never silently stalls.
- **Combat**: Firing is hitscan, not projectile-based — pressing `Space` checks whether an enemy sprite occupies the dead-center screen column and is closer than the nearest wall in that column (via the Z-buffer). One hit = 1 damage. On kill, the enemy is removed and an enemy of the same type is immediately respawned elsewhere, keeping the total enemy count constant indefinitely.
- **Restart**: `R` resets player position, direction, kill count, and the enemy list back to the initial spawn state. It does not reload the extension or reset HPR itself.

### Known constraints

- **No persistence**: Kill count, position, and enemy state all live in memory only. Closing or restarting HPR resets everything — there is no save file and no database table.
- **No collision against enemies**: Enemies path directly toward the player but currently do not deal damage or have any attack of their own — this is a target-practice-style build, not a survival shooter.
- **Single weapon**: Only the shotgun is implemented; there's no weapon switching.
- **Fixed map**: The level is hardcoded in the script. Changing it means editing the `map` table directly — there's no level loader.
- **Performance**: Tick rate is set to 20 (interpreted by HPR as milliseconds per tick, i.e. ~50 ticks/sec) in `init()`'s return value. Lowering this number increases responsiveness at the cost of more CPU time spent re-rendering the full 160×120 buffer every tick.

---

## License

GPLv3, per the root repository license, unless stated otherwise.
