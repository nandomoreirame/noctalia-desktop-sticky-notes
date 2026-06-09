# Context Handoff — desktop-sticky-notes

> Full context from the research/plan conversation, so a fresh session in this repo
> can continue with zero loss. Read this before touching code.
> Date: 2026-06-09.

## Purpose

A Noctalia Shell plugin: **sticky notes pinned on the desktop as desktop widgets**.
Each note is a draggable/scalable instance with Markdown text, background color
(post-it palette), text color and font size. Editing opens a focused popup panel.

## Research decisions (already made — do not re-ask)

1. **Starting point:** adapt the `custom-sticker` plugin (already a per-instance draggable desktop widget).
2. **Editing:** popup panel on click (NOT inline) — `Panel.qml` opened via `pluginApi.openPanel(screen)`.
3. **Customization (MVP):** background color + text color + font size + Markdown — all four.
4. **Versioning:** own git repo (`~/dev/projects/noctalia-desktop-sticky-notes`) + symlink into
   `~/.config/noctalia/plugins/desktop-sticky-notes`.

## Environment / versions

- **Noctalia:** `noctalia-shell 4.7.7-3`, `noctalia-qs 0.0.12`. Target `minNoctaliaVersion 4.6.6`.
- `~/.config/noctalia` → `~/.dotfiles/configs/noctalia` (symlink).
- Installed plugins live in `~/.dotfiles/configs/noctalia/plugins/` but that dir is **gitignored** in the
  dotfiles (only `plugins.json`, the enabled-list, is tracked). That is why this plugin uses its own repo.
- Noctalia QML module source (system, read-only): `/etc/xdg/quickshell/noctalia-shell/`.
- The `sticky-notes` (markdown, panel/bar) plugin is already installed & enabled on this machine — different
  plugin, do not confuse with this one.

## Key technical findings

### `DraggableDesktopWidget` (the base class to extend)

Source: `/etc/xdg/quickshell/noctalia-shell/Modules/DesktopWidgets/DraggableDesktopWidget.qml`
(local copy: `docs/reference/_noctalia-DesktopWidgets-module/`).

Inherited properties: `screen` (ShellScreen), `widgetData` (per-instance config object),
`widgetIndex`, `isDragging`, `isScaling` (read-only), `showBackground`, `roundedCorners`,
`widgetScale` (min 0.5, max **5.0**, default 1.0), `defaultX/defaultY`, and `content`
(default property alias — children go into the content container).

Functions on the base:

- **`updateWidgetData(properties)`** — THE central persistence call. Internally:
  `DesktopWidgetRegistry.updateWidgetData(screen.name, widgetIndex, properties)`.
  Persists into `Settings.data.desktopWidgets.monitorWidgets`. `widgetData` is reactive
  (`onWidgetDataChanged`), so the widget re-renders after a write.
- `removeWidget()`, `raiseToTop()`, `lowerToBottom()`, `openWidgetSettings()`, `handleContextMenuAction(action)`.

Behavior:

- Drag, corner-scale handles and the right-click context menu (reset / raise / lower / delete /
  widget-settings) are only active in **edit mode** (`DesktopWidgetRegistry.editMode`). Outside edit
  mode the widget surface is free, so a click MouseArea (`visible: !editMode`) can open the editor.
- `import qs.Services.Noctalia` to reach `DesktopWidgetRegistry`.

### `pluginApi` (injected into every plugin component by PluginService)

Properties: `pluginId`, `pluginDir`, `pluginSettings` (read/write, plugin-global), `manifest`,
`currentLanguage`, `mainInstance` (the instantiated `Main.qml`), `barWidget`.

Functions: `saveSettings()` (persists `pluginSettings` to `plugins/<id>/settings.json`),
`openPanel(screen, buttonItem?)`, `closePanel(screen)`, `togglePanel(screen, buttonItem?)`,
`tr(key, interpolations)`, `trp(key, count, ...)`, `hasTranslation(key)`.

Services reachable from plugin QML: `qs.Commons` (Settings, I18n, Logger, Style, Color),
`qs.Services.UI` (ToastService, PanelService, TooltipService), `qs.Services.System`
(AudioService, BatteryService, NetworkService), `qs.Widgets` (NText, NTextInput, NButton,
NIconButton, NColorPicker, NValueSlider, NToggle, NScrollView, NFilePicker, NLabel, ...).

### Two persistence models (pick per-instance for notes)

| Model | Read | Write | Used by | Scope |
|-------|------|-------|---------|-------|
| **Per-instance** | `widgetData.X` | `updateWidgetData({X})` / settings panel `widgetSettings.data.X` + `widgetSettings.save()` | `custom-sticker` | this widget instance |
| Plugin-global | `pluginApi.pluginSettings.X` | `pluginApi.pluginSettings.X = v; pluginApi.saveSettings()` | `todo` | whole plugin (bar+panel+desktop) |

**This plugin uses per-instance** (`widgetData`): each note is one widget instance with its own
`text`, `bgColor`, `textColor`, `fontSize` (+ `x`/`y`/`scale` managed by the base).

### The central edit/persist loop (also the SPIKE to prove first)

```
click note (outside edit mode)
  -> Main.qml store: setActive(screen.name, widgetIndex)
  -> pluginApi.openPanel(screen)               // Panel is a shell window -> gets keyboard focus
  -> edit text/color/font in Panel
  -> DesktopWidgetRegistry.updateWidgetData(screenName, widgetIndex, { text, bgColor, textColor, fontSize })
  -> widgetData changes (reactive) -> note re-renders
```

Risk being validated by the spike (plan Task 4): (1) desktop widgets sit on the background layer and
may not get keyboard focus — the Panel route is the mitigation; (2) one global Panel must know WHICH of
N notes opened it — solved via the `Main.qml` `{screenName, widgetIndex}` store.

### manifest.json schema (relevant fields)

`id` (kebab, == dir name), `name`, `version`, `minNoctaliaVersion`, `author`, `license`,
`repository`, `description`, `tags[]`, `entryPoints{ main, desktopWidget, desktopWidgetSettings,
panel, barWidget, controlCenterWidget, launcherProvider, settings }`, `dependencies.plugins[]`,
`metadata.defaultSettings{}`, `metadata.commandPrefix`. All entry points optional (>=1 required).

### markdown.js

`sticky-notes/utils/markdown.js` is a self-contained `.pragma library` Markdown->Qt-RichText parser
(AST -> renderer, does `escapeHtml`, supports bold/italic/code/lists/tasks/quotes/tables/links/images).
**Vendor it verbatim** into `utils/markdown.js` (plan Task 5). It is the XSS guard for note text
(Iron Law #4/#8). Local copy: `docs/reference/sticky-notes/utils/markdown.js`.

## Reference material (local, gitignored under `docs/reference/`)

| Path | Why it matters |
|------|----------------|
| `_noctalia-DesktopWidgets-module/DraggableDesktopWidget.qml` | The base class — full API, drag/scale/context-menu, `updateWidgetData` |
| `_noctalia-DesktopWidgets-module/DesktopWidgets.qml` | How the shell instantiates widgets (sets `screen`, `widgetData`, `widgetIndex`) |
| `custom-sticker/*` | Structural base (per-instance desktop widget + DesktopWidgetSettings pattern) |
| `todo/*` | Persistence patterns, `Main.qml` store, expandable desktop widget |
| `sticky-notes/components/ExpandedNoteWindow.qml` | Base for `Panel.qml` editor (TextArea edit/preview, shortcuts) |
| `sticky-notes/utils/markdown.js` | To vendor verbatim |
| `calendar-widget/*` | Extra desktop-widget example (minimal, with settings) |

`docs/reference/` is gitignored on purpose (third-party code, kept only for context; never goes in the PR).

### How to re-fetch references if missing

```bash
git clone --depth 1 https://github.com/noctalia-dev/noctalia-plugins /tmp/noctalia-plugins
# base module is always installed at:
ls /etc/xdg/quickshell/noctalia-shell/Modules/DesktopWidgets/
```

## Gotchas hit during this session (reusable)

- **RTK `ls`/`find` lie about populated dirs:** they printed `(empty)` / `0 for '*'` for dirs that
  actually had files. Use `/usr/bin/ls` and `/usr/bin/find` for authoritative checks.
- **The harness refuses to write through a symlink.** Edit the real path
  (`~/.dotfiles/configs/...`), not the `~/.config` symlink.
- **WebFetch:** several `docs.noctalia.dev` pages 403 or redirect to `/v4/`; the working doc pages are
  under `/v4/development/plugins/<page>/`. Source code is the authoritative reference.

## Current state

- `docs/specs/2026-06-09-desktop-sticky-notes.md` — validated spec (13 REQs).
- `docs/plans/2026-06-09-desktop-sticky-notes.md` — 14-task TDD plan.
- `docs/STATE.md` — RPI state (`phase: plan-complete`).
- `git init` done. Branch renamed to **`main`** (trunk-based, decided 2026-06-09). **Nothing committed yet.**
- Remote `origin` set to `git@github.com:nandomoreirame/noctalia-desktop-sticky-notes.git` (private repo).
- Symlink into `~/.config/noctalia/plugins/` **not created yet** (plan Task 2).
- `.gitignore` already created.

## Next steps

1. `/rpi:implement` against `docs/plans/2026-06-09-desktop-sticky-notes.md`.
2. **Task 4 is the gate:** prove the click->panel->`updateWidgetData`->re-render loop and keyboard focus
   before building the full UI. If it fails, revisit AD-002/AD-003 in the spec.

## Decisions confirmed (was "open items")

- **Repo URL:** `https://github.com/nandomoreirame/noctalia-desktop-sticky-notes` (private). Use this in
  `manifest.json` `repository` when scaffolded.
- **Branch model:** trunk-based on `main` (no `develop`, no git-flow). Confirmed 2026-06-09.
- Plugin `id`/name confirmed: `desktop-sticky-notes` / "Desktop Sticky Notes".
