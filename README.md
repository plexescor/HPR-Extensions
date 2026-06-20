# HPR-Extensions

Official and community-contributed extensions for [HPR (Human Pattern Recorder)](https://github.com/plexescor/HPR) - the lightweight, privacy-first, C++23 activity tracker.

This repository is the central hub for HPR extensions written in Lua. Every extension here has been reviewed and approved. No malicious code. No surprises.

---

## What is an HPR Extension?

HPR has a built-in Lua scripting engine that lets you extend its behavior without touching a single line of C++. Extensions are plain `.lua` files that HPR automatically discovers and loads from your extensions folder at startup.

Each extension runs on its own dedicated background thread with its own isolated Lua VM, its own stack, and its own heap. Extensions communicate with HPR through a controlled API exposed via the global `HPR` table, and can communicate with each other through HPR's built-in EventHub pub/sub system.

Want to learn how to write your own extension? The full API reference, tutorials, and working examples are on the **[HPR Extension Documentation](https://hpr-cpp.netlify.app/docs.html)**.

---

## Installation

### Step 1 - Find the extension you want

Browse the folders in this repository. Each extension has its own subfolder with a `README.md` explaining what it does, what it requires, and any setup steps specific to that extension.

### Step 2 - Copy the `.lua` file(s) to your HPR extensions folder

**Linux:**
~/.config/HPR/extensions/
**Windows:**
%APPDATA%\HPR\HPR_Config\extensions\

You can organize extensions into subfolders. HPR scans recursively so a structure like this works perfectly:

extensions/
    spotify-tracker/
    spotify.lua
    sway-backend/
    sway.lua
    my-other-thing.lua

### Step 3 - His RESCAN
Hit RESCAN button in extension view

---

## Official Extensions

* **Budget Doom**: A self-contained raycasted FPS rendered entirely inside HPR's miscellaneous image panel. No requirements beyond enabling the panel in UI settings. See its [README](./official-extensions/budget-doom/README.md) for full details.

---

## Community Extensions

Community extensions are submitted via pull request and reviewed before merging. If an extension passes review it gets listed here with the author credited.

| Extension | Author | Description |
|-----------|--------|-------------|
| *(none yet - be the first!)* | - | - |

---

## Submitting a Community Extension

Want your extension listed here? Open a pull request.

Create a subfolder with your extension name, place your `.lua` file(s) inside it, and include a `README.md` that explains what the extension does, what it requires, and how to install it.

Every submitted extension is reviewed by plexescor before merging. The review checks for malicious behavior, correct cleanup of event subscriptions, safe SQL usage, and general code quality. Extensions that pass get merged. Extensions that fail get feedback and can be resubmitted.

For everything you need to know about writing extensions - the full API reference, lifecycle hooks, database access, UI integration, EventHub, and working tutorial examples - see the **[HPR Extension Documentation](https://hpr-cpp.netlify.app/docs.html)**.

---

## Rules for All Extensions

These rules apply to every extension in this repository.

**No network exfiltration.** No calls to unknown or untrusted external servers. Extensions may make localhost network calls (e.g. reading from a local service) but must never send data to external servers without explicit user knowledge and consent documented in the extension's README.

**No destructive system commands.** HPR blocks dangerous commands at the C++ level. Extensions must not attempt to work around this.

**Always clean up event subscriptions.** Every `HPR.connect_E` call must have a matching `HPR.disconnect_E` in `onExit()`. Leaked subscriptions cause memory leaks in HPR's C++ event registry.

**Use parameterized SQL queries.** Never concatenate data into SQL strings. Always use `?` placeholders.

**Use unique table names.** All extensions share HPR's SQLite database. Prefix your table names with your extension name to avoid conflicts with HPR's core tables and other extensions.

**No hardcoded personal paths.** Extensions must work on any user's machine.

**Handle errors with pcall.** Wrap database operations and anything that can fail in `pcall` so a bad tick does not kill your extension thread.

---
## License

All extensions in this repository are licensed under the GPLv3 License unless the individual extension's folder specifies otherwise.

---

## Links

- [HPR Main Repository](https://github.com/plexescor/HPR)
- [HPR Extension Documentation](https://hpr-cpp.netlify.app/docs.html)
- [HPR Website](https://hpr-cpp.netlify.app)
- [Ko-fi](https://ko-fi.com/plexescor)