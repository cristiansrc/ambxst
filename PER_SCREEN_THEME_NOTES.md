# Per-Screen Color Theming — Research & Lessons Learned

## Goal
Allow each monitor to have its own color palette generated from that monitor's wallpaper, while keeping the global UI (dashboard, bar, notifications) on the primary monitor's colors.

## Architecture Overview

### Color Pipeline
1. **matugen** (Material You color generator) reads `~/.cache/ambxst/colors.json` and generates a palette
2. **`Colors.qml`** (`modules/theme/Colors.qml`) watches `~/.cache/ambxst/colors.json` via `FileView`. Any change to that file triggers reactive UI updates globally.
3. **`Config.theme.lightMode`** controls dark/light theme. When toggled, `Config.qml` re-runs matugen with the scheme applied.
4. **`SchemeSelector.qml`** (`modules/widgets/dashboard/wallpapers/SchemeSelector.qml`) lets the user pick a color preset (Ayu, Catppuccin, Tonal Spot, etc.). This is **global** — it writes to matugen config and regenerates `colors.json`.

### Current Color Files
- `~/.cache/ambxst/colors.json` — global palette, read by `Colors.qml`
- `~/.cache/ambxst/colors_<screenName>.json` — per-screen palettes (created by our Python script), but **NOT watched by `Colors.qml`**

## What Was Implemented

### Per-Screen Wallpaper → Color Generation
- **`Wallpaper.qml::runMatugenForCurrentWallpaper(screenName?)`** — accepts optional `screenName`. When provided and `perScreenWallpapers[screenName]` exists, generates colors from that monitor's wallpaper and writes to `colors_<screenName>.json`.
- **`/tmp/ambxst_ps.py`** — Python script that reads matugen config, modifies only `output_path` to `~/.cache/ambxst/colors_<screen>.json`, writes a temp config to the original config directory (preserving relative `input_path`), runs matugen, and cleans up.
- **`Wallpaper.qml::setWallpaper(path, targetScreen)`** — now always calls `runMatugenForCurrentWallpaper(targetScreen)` outside the primary-guard, so secondary monitors always run matugen with their per-screen wallpaper.

### Why Python Script Instead of Inline
- QML has string escaping issues with bash commands (tilde `~` vs expanded paths, quotes)
- matugen's config uses `input_path` relative to the config directory; the temp config must be in the same directory
- Direct write approach avoids the backup/restore flash (`colors.json.bak` approach caused all monitors to briefly show wrong colors)

## Difficulties & Blockers

### 1. `Colors.qml` Only Watches One File
`Colors.qml` uses `FileView` on `~/.cache/ambxst/colors.json`. There's no mechanism to watch per-screen files. To make per-screen colors work per-monitor, `Colors.qml` would need to:
- Know which screen it's being rendered on
- Watch the appropriate `colors_<screenName>.json` file
- This requires `Colors` singleton to be instantiated per-screen (not global)

### 2. Colors Singleton Is Global
`Colors.qml` is a `pragma Singleton`. All components import it directly. Making it per-screen would require:
- Converting it to a regular QML component that can be instantiated via `Variants { model: Quickshell.screens }`
- Threading the per-screen Colors instance through every component that currently imports the global singleton
- This touches virtually every QML file in the project

### 3. Per-Screen Scheme Selector Race Conditions
Attempted to make `SchemeSelector.qml` per-screen, but:
- Three instances fire `onActiveColorPresetChanged` simultaneously
- UI selector items above "Tonal Spot" became unresponsive
- `AxctlService` crashes during rapid scheme switching, breaking `currentScreenName`

### 4. Qt Quick / QML Limitations
- No built-in per-screen singleton pattern; would need custom implementation
- Property bindings across screen variants are complex
- `AxctlService` JSON parse errors (`AxctlService subscribe JSON parse error`) cause `focusedMonitor` to be null — pre-existing bug unrelated to our changes

### 5. matugen Config Limitations
- `input_path` is relative to the config directory, so temp config must be in the same directory
- matugen generates a full palette; there's no incremental/diff mode
- Running matugen multiple times (one per screen) is expensive

## Key Files

| File | Path | Role |
|------|------|------|
| Colors.qml | `modules/theme/Colors.qml` | Global singleton, watches `colors.json` |
| Wallpaper.qml | `modules/widgets/dashboard/wallpapers/Wallpaper.qml` | Contains `runMatugenForCurrentWallpaper()`, `setWallpaper()`, per-screen wallpaper storage |
| WallpapersTab.qml | `modules/widgets/dashboard/wallpapers/WallpapersTab.qml` | Grid UI, per-screen checkbox, scheme selector |
| SchemeSelector.qml | `modules/widgets/dashboard/wallpapers/SchemeSelector.qml` | Global color preset picker |
| Config.qml | `config/Config.qml` | Contains `lightMode`, `autoTheme`, `updateAutoTheme()` |
| matugen config | `assets/matugen/config.toml` | Template for matugen configuration |
| Python script | `/tmp/ambxst_ps.py` | Per-screen matugen runner (must persist across restarts) |
| GlobalStates.qml | `modules/globals/GlobalStates.qml` | Transient state, dashboard open/close flags |

## What Would Need to Change for True Per-Monitor Colors

### Option A: Watch Multiple Files in Colors.qml
1. Make `Colors.qml` watch a directory, not a single file
2. Add a `screenName` property
3. Load the appropriate `colors_<screenName>.json` based on the screen
4. Thread the screen-aware Colors instance through components

### Option B: Per-Screen Colors Instances
1. Convert `Colors.qml` from singleton to regular component
2. Instantiate via `Variants { model: Quickshell.screens }`
3. Each instance watches its own `colors_<screenName>.json`
4. Components that need per-screen colors must receive the correct instance (breaking change across all QML files)

### Option C: Symbolic Link Swap
1. Keep `Colors` as global singleton watching `colors.json`
2. On screen focus change, symlink `colors.json` → `colors_<focusedScreen>.json`
3. Simple but means all monitors flash when focus changes
4. Not recommended

### Prerequisites for Any Option
- **Fix `AxctlService` JSON parse errors** — per-screen features depend on `currentScreenName` / `focusedMonitor`
- **Stabilize SchemeSelector** — avoid race conditions when multiple instances exist
- **Decide on UI**: should the bar/dashboard show per-screen colors or primary? The current implementation keeps global UI on primary colors.

## What Works Today
- Per-screen wallpaper changes generate correct per-screen color files (`colors_<screenName>.json`)
- Global UI (dashboard, bar, notifications) remains on primary monitor's colors
- Scheme/preset selection works globally
- Per-screen wallpaper mode toggle in WallpapersTab works

## What Does Not Work (Not Implemented)
- Per-screen colors are generated but never consumed by the UI
- `Colors.qml` still only reads `colors.json`
- No mechanism to apply per-screen colors per-monitor

## Lost Features
- **Auto light/dark theme** — was in uncommitted QML changes; destroyed by `git checkout`. User must reimplement if needed.
- **Original shell sun/moon bar button** — from upstream template; not re-implemented in this fork. The Claro/Oscuro/Auto toggle exists in WallpapersTab.qml as a SegmentedSwitch.

## Refs
- matugen config: `~/.local/src/ambxst/assets/matugen/config.toml`
- Per-screen Python script: `/tmp/ambxst_ps.py`
- Per-screen color files: `~/.cache/ambxst/colors_*.json`
- Repo: `/home/cristiansrc/.local/src/ambxst/`
- Source repo for restore: `/home/cristiansrc/Documentos/Proyectos/ambxst/`
- Backup: `/home/cristiansrc/.local/src/ambxst.bak/`
