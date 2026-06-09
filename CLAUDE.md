# CLAUDE.md

Context for Claude Code working in this repository.

## Project Overview

**desktop-sticky-notes** — a Noctalia Shell (Quickshell) plugin that pins sticky notes on the
desktop as **desktop widgets**. Each note is a draggable/scalable instance with Markdown text,
background color (post-it palette), text color and font size. Editing opens a focused popup panel.

> **Read `docs/CONTEXT.md` first.** It carries the full handoff from the research/plan session:
> all decisions, the Noctalia API findings (`DraggableDesktopWidget`, `pluginApi`, `updateWidgetData`),
> reference plugins, and gotchas. Do not re-ask the research questions — they are decided.

## Status

Research + Plan done. Implementation not started. See `docs/STATE.md`.

- Spec: `docs/specs/2026-06-09-desktop-sticky-notes.md`
- Plan: `docs/plans/2026-06-09-desktop-sticky-notes.md` (14 tasks; **Task 4 is the spike/gate**)
- Next: `/rpi:implement`

## Tech Stack

- **QML** (Quickshell + Noctalia 4.x modules) — the widget, editor panel, settings.
- **JavaScript** — `utils/markdown.js` (vendored), `utils/palette.js`.
- **Vitest** (Node) — unit tests for the JS-only logic.

## Central mechanism (memorize this)

Notes persist **per instance** via the base class:

```qml
// inside a DraggableDesktopWidget subclass
root.updateWidgetData({ text: "...", bgColor: "#FFF9C4", textColor: "#37474F", fontSize: 14 })
// -> DesktopWidgetRegistry.updateWidgetData(screen.name, widgetIndex, props)  (reactive)
```

The editor is `Panel.qml`, opened with `pluginApi.openPanel(screen)` (a shell window → keyboard focus).
`Main.qml` holds `{activeScreenName, activeWidgetIndex}` so the single Panel knows which note to save.

## Key paths

- Base class (system, read-only): `/etc/xdg/quickshell/noctalia-shell/Modules/DesktopWidgets/`
- Reference plugins (local, gitignored): `docs/reference/` (custom-sticker, todo, sticky-notes, calendar-widget)
- Live load target (symlink, created in plan Task 2): `~/.config/noctalia/plugins/desktop-sticky-notes`

## Commands

```bash
# JS unit tests (TDD for markdown.js / palette.js)
npx vitest run

# reload the running shell after a QML change and watch for errors
qs -c noctalia-shell &            # or restart via Super+Alt+B
journalctl --user -b 0 | grep -iE "noctalia|quickshell" | tail -30
```

## Conventions

- All code, identifiers, comments, commits, README and i18n in **English**.
- **Conventional Commits** with a leading Unicode emoji (e.g. `✨ feat(widget): ...`, `🔧 chore: ...`).
- **TDD** strict for JS (Vitest, Red→Green→Refactor). QML UI verified by reloading `qs` + a manual checklist.
- `showBackground: false` on the note; draw the colored post-it background manually.
- Scale every dimension/font with `Math.round(value * widgetScale)` (crisp text).
- Note text is user input rendered as RichText → must pass through `markdown.js` `escapeHtml` (XSS guard).

## Noctalia

- Installed: `noctalia-shell 4.7.7`; plugin targets `minNoctaliaVersion 4.6.6`.
- `~/.config/noctalia` → `~/.dotfiles/configs/noctalia` (the harness can't write through that symlink;
  this plugin lives in its own repo, symlinked into `plugins/`).
