# Spec: desktop-sticky-notes (Noctalia plugin)

- **Date:** 2026-06-09
- **Status:** validated (research complete)
- **Type:** desktop widget plugin for Noctalia Shell (Quickshell)
- **Repo:** `~/dev/projects/noctalia-desktop-sticky-notes` (symlink → `~/.config/noctalia/plugins/desktop-sticky-notes`)
- **Noctalia target:** `minNoctaliaVersion 4.6.6` (installed: 4.7.7)

## 1. Vision

Sticky notes that stay pinned on the desktop as Noctalia **desktop widgets**. Each
note is draggable, scalable and persistent. The text supports Markdown, a background
color (post-it palette), a text color and a font size, all per instance. Editing the
text opens a **popup with keyboard focus** (a shell Panel).

Decisions from the research phase:

1. **Starting point:** adapt the `custom-sticker` plugin (already a per-instance draggable desktop widget).
2. **Editing:** popup on click (not inline) via `Panel.qml`, opened through `pluginApi.openPanel`.
3. **Customization (MVP):** background color + text color + font size + Markdown.
4. **Versioning:** own repo + symlink into `~/.config/noctalia/plugins/`.

## 2. Architecture

```
noctalia-desktop-sticky-notes/
  manifest.json                # id: desktop-sticky-notes
  DesktopWidget.qml            # the note on the desktop (markdown preview + colored background)
  DesktopWidgetSettings.qml    # per-instance customization (color/font), via context menu in edit mode
  Panel.qml                    # popup editor with keyboard focus (base: ExpandedNoteWindow from sticky-notes)
  Main.qml                     # lightweight store: active note context (screenName, widgetIndex)
  utils/markdown.js            # standalone parser copied verbatim from sticky-notes
  i18n/en.json, i18n/pt.json
  preview.png, README.md, LICENSE
```

### AD-001: Instance model

1 note = 1 desktop widget instance (like `custom-sticker`). The user adds N notes
through Settings → Desktop Widgets. Per-instance state lives in `widgetData`:
`text`, `bgColor`, `textColor`, `fontSize` (+ `x`/`y`/`scale` managed by the base class).

### AD-002: Persistence (central mechanism)

`DraggableDesktopWidget` exposes `updateWidgetData(properties)`, which calls
`DesktopWidgetRegistry.updateWidgetData(screen.name, widgetIndex, properties)` and persists into
`Settings.data.desktopWidgets.monitorWidgets`. `widgetData` is reactive (`onWidgetDataChanged`).

Flow:

```
click the note (outside edit mode)
  → store {screenName, widgetIndex} in the store (Main.qml)
  → pluginApi.openPanel(screen)
  → edit in the Panel
  → DesktopWidgetRegistry.updateWidgetData(screenName, widgetIndex, {text,bgColor,textColor,fontSize})
  → widgetData changes → note re-renders
```

### AD-003: Editor is a Panel, not inline

Desktop widgets sit on the background layer and do not reliably receive keyboard focus.
The editor is `Panel.qml`, opened via `pluginApi.openPanel(screen)` (a shell window that gets focus).
Content based on `sticky-notes`'s `ExpandedNoteWindow.qml` (editable TextArea + RichText preview).

### AD-004: Reused Markdown

`utils/markdown.js` copied verbatim from `sticky-notes` (a dependency-free `.pragma library` parser,
already validated in production, performs `escapeHtml`). Do not rewrite; only add regression tests if changed.

## 3. Requirements

### P1 (mandatory MVP)

- **REQ-001:** WHEN the user adds the widget through Settings → Desktop Widgets, THEN an empty note with the default color SHALL appear on the desktop, draggable and scalable.
- **REQ-002:** WHEN the user clicks a note outside edit mode, THEN the popup editor (Panel) SHALL open with keyboard focus and the current text loaded.
- **REQ-003:** WHEN the user saves in the editor (Ctrl+S / Esc / button), THEN the text SHALL persist into the correct instance's `widgetData.text` via `updateWidgetData`.
- **REQ-004:** WHEN there is Markdown text, THEN the desktop note SHALL render it as read-only RichText, scaled by `widgetScale`.
- **REQ-005:** WHEN the shell restarts, THEN each note SHALL restore its text, color, font, position and scale.
- **REQ-006:** WHEN multiple notes exist, THEN each SHALL keep independent state (editing one does not affect the others).
- **REQ-007:** WHEN the user picks a background color (post-it palette), THEN the note SHALL apply and persist `bgColor`.

### P2 (desirable in MVP)

- **REQ-008:** Configurable text color (`NColorPicker`) persisted in `textColor`.
- **REQ-009:** Configurable font size (independent of `widgetScale`) persisted in `fontSize`.
- **REQ-010:** `DesktopWidgetSettings.qml` offers color/font through the context menu in edit mode.
- **REQ-011:** i18n en + pt.

### P3 (post-MVP)

- **REQ-012:** `preview.png` + `README.md` ready for a PR to `noctalia-plugins`.
- **REQ-013:** Shortcut to quickly create a new note.

## 4. Constraints

- **C-001:** `showBackground: false`; the note draws its own `Rectangle` with `bgColor` (post-it look).
- **C-002:** the click-to-edit `MouseArea` is only `visible: !DesktopWidgetRegistry.editMode` (must not conflict with drag/scale).
- **C-003:** all dimensions scaled with `Math.round(value * widgetScale)` (crisp text).
- **C-004:** disable expensive effects (shadow/layer) during `isScaling`/`isDragging`.
- **C-005:** code, identifiers and commits in English; README/i18n default in English (registry).
- **C-006:** Iron Law #4/#8: user input (note text) rendered as RichText MUST pass through `escapeHtml` (already in `markdown.js`); validate that malicious input does not break the render.

## 5. Testing strategy

- **markdown.js:** Vitest (node), pure JS. Copied verbatim; regression tests only if changed.
- **Own JS logic** (color palette, defaults, sanitization): TDD Red→Green→Refactor with Vitest.
- **QML UI:** manual validation by reloading `qs -c noctalia-shell` + log check; acceptance checklist covering REQ-001..011.

## 6. Risks

| Risk | Mitigation | Becomes task |
|------|------------|--------------|
| Keyboard focus in the editor | Panel via `pluginApi.openPanel` | Spike 0 |
| Global Panel → which note opened it | Context store `{screenName, widgetIndex}` in Main.qml | Spike 0 |
| Click vs. drag in edit mode | `visible: !editMode` on the MouseArea | REQ-002 |
| RichText on the background layer | Already proven by `sticky-notes` | low |

**Spike 0 (first task):** a hello-world widget that, on click, opens the Panel and writes a field
via `updateWidgetData`, confirming the full persistence loop before building the real UI.
