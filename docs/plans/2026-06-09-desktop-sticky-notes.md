# Plan: desktop-sticky-notes

> **Spec:** docs/specs/2026-06-09-desktop-sticky-notes.md

**Goal:** Build a Noctalia desktop widget plugin where each instance is a draggable, scalable sticky note with Markdown text, background/text color and font size, edited through a focused popup panel and persisted per instance.

**Architecture:** Each note is a `DraggableDesktopWidget` instance storing state in `widgetData`. Clicking a note (outside edit mode) stores its `{screenName, widgetIndex}` in a lightweight `Main.qml` store and opens `Panel.qml` (a shell window with keyboard focus) as the editor. Saving writes back through `DesktopWidgetRegistry.updateWidgetData(screenName, widgetIndex, props)`, which is reactive. Markdown rendering reuses the standalone `markdown.js` from the `sticky-notes` plugin.

**Tech Stack:** QML (Quickshell / Noctalia 4.x modules), JavaScript (`markdown.js`), Vitest (Node) for JS unit tests.

**Total Tasks:** 14
**Estimated Complexity:** large (9+)

**Verification convention (QML tasks):** Quickshell QML has no practical unit-test harness, so UI tasks are verified by reloading the shell and observing behavior + logs:

```bash
# reload the running shell and watch for QML errors
qs -c noctalia-shell &                     # or restart via Super+Alt+B
journalctl --user -b 0 | grep -iE "noctalia|quickshell" | tail -30
```

JS tasks (markdown, color/sanitization logic) follow strict TDD with Vitest.

**Dependency note:** Tasks 1-4 are sequential and gate everything else. Task 4 (the spike) must prove the click -> panel -> updateWidgetData -> re-render loop before Tasks 7-12 are built; if `openPanel` cannot carry per-instance context, revisit AD-002/AD-003 before continuing.

---

## Phase 0 — Setup & Scaffolding

### Task 1: Create manifest and base files

**Requirement:** REQ-001 (foundation)
**Files:**

- Create: `manifest.json`
- Create: `.gitignore`
- Create: `LICENSE` (MIT)

**Step 1: Write `manifest.json`**

```json
{
  "id": "desktop-sticky-notes",
  "name": "Desktop Sticky Notes",
  "version": "0.1.0",
  "minNoctaliaVersion": "4.6.6",
  "author": "Fernando Moreira",
  "license": "MIT",
  "repository": "https://github.com/nandomoreirame/noctalia-desktop-sticky-notes",
  "description": "Sticky notes you can pin on the desktop as desktop widgets, with Markdown, colors and per-note font size.",
  "tags": ["Desktop", "Productivity", "Notes"],
  "entryPoints": {
    "main": "Main.qml",
    "desktopWidget": "DesktopWidget.qml",
    "desktopWidgetSettings": "DesktopWidgetSettings.qml",
    "panel": "Panel.qml"
  },
  "dependencies": { "plugins": [] },
  "metadata": {
    "defaultSettings": {
      "showBackground": false,
      "defaultBgColor": "#FFF9C4",
      "defaultTextColor": "#37474F",
      "defaultFontSize": 14
    }
  }
}
```

**Step 2: Write `.gitignore`**

```
*.qmlc
*.jsc
node_modules/
```

**Step 3: Write `LICENSE`** — standard MIT text, author "Fernando Moreira", year 2026.

**Step 4: Verify** — `python -c "import json,sys; json.load(open('manifest.json'))"` exits 0 (valid JSON).

**Step 5: Commit** — `/git commit`

---

### Task 2: Symlink plugin into Noctalia and confirm discovery

**Requirement:** REQ-001
**Files:** none (filesystem + runtime)

**Step 1: Create the symlink**

```bash
ln -sfn "$HOME/dev/projects/noctalia-desktop-sticky-notes" \
        "$HOME/.config/noctalia/plugins/desktop-sticky-notes"
ls -ld ~/.config/noctalia/plugins/desktop-sticky-notes
```

**Step 2: Verify discovery** — restart the shell (`Super+Alt+B` or `qs -c noctalia-shell`), open Settings → Plugins. Expected: `Desktop Sticky Notes` appears in the list (may need enabling). Confirm no manifest parse error in `journalctl --user -b 0 | grep -i noctalia`.

**Step 3: Commit** — nothing to commit (runtime only); note completion in STATE.md.

---

## Phase 1 — Spike: prove the persistence loop

### Task 3: Minimal DesktopWidget renders on the desktop

**Requirement:** REQ-001
**Files:**

- Create: `DesktopWidget.qml`

**Step 1: Write a minimal note widget (fixed color + placeholder label)**

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets

DraggableDesktopWidget {
  id: root
  property var pluginApi: null

  showBackground: false

  readonly property string noteText: widgetData?.text ?? ""
  readonly property color noteBg: widgetData?.bgColor ?? "#FFF9C4"

  readonly property int baseW: 200
  readonly property int baseH: 140
  implicitWidth: Math.round(baseW * widgetScale)
  implicitHeight: Math.round(baseH * widgetScale)
  width: implicitWidth
  height: implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: Math.round(Style.radiusM * root.widgetScale)
    color: root.noteBg
    border.width: 1
    border.color: Qt.darker(root.noteBg, 1.08)

    NText {
      anchors.centerIn: parent
      text: root.noteText !== "" ? root.noteText : "Sticky note"
      color: "#37474F"
      pointSize: Math.round(Style.fontSizeM * root.widgetScale)
    }
  }
}
```

**Step 2: Verify** — reload shell, enter Desktop Widgets edit mode, add `Desktop Sticky Notes`. Expected: a yellow note with "Sticky note" appears; it drags and scales. No QML errors in journal.

**Step 3: Commit** — `/git commit`

---

### Task 4 (SPIKE): Prove click -> panel -> updateWidgetData loop

**Requirement:** REQ-002, REQ-003 (mechanism validation)
**Files:**

- Create: `Main.qml` (context store)
- Create: `Panel.qml` (minimal editor)
- Modify: `DesktopWidget.qml` (add click handler)

**Step 1: `Main.qml` — lightweight active-note store**

```qml
import QtQuick
import qs.Commons

Item {
  id: root
  property var pluginApi: null
  // context of the note currently being edited
  property string activeScreenName: ""
  property int activeWidgetIndex: -1

  function setActive(screenName, widgetIndex) {
    activeScreenName = screenName;
    activeWidgetIndex = widgetIndex;
  }
}
```

**Step 2: `Panel.qml` — minimal editor that writes a test field back**

```qml
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Services.Noctalia
import qs.Widgets

Item {
  id: root
  property var pluginApi: null
  readonly property var store: pluginApi?.mainInstance

  implicitWidth: 420
  implicitHeight: 240

  Rectangle {
    anchors.fill: parent
    color: Color.mSurface
    radius: Style.radiusL

    Column {
      anchors.centerIn: parent
      spacing: Style.marginM

      NTextInput {
        id: input
        width: 320
        text: ""
      }
      NButton {
        text: "Save"
        onClicked: {
          var s = root.store;
          if (s && s.activeWidgetIndex >= 0) {
            DesktopWidgetRegistry.updateWidgetData(
              s.activeScreenName, s.activeWidgetIndex, { "text": input.text });
          }
          if (root.pluginApi) root.pluginApi.closePanel(null);
        }
      }
    }
  }
}
```

**Step 3: Wire the click in `DesktopWidget.qml`** — add inside the root, before the closing brace:

```qml
  MouseArea {
    anchors.fill: parent
    visible: !DesktopWidgetRegistry.editMode
    acceptedButtons: Qt.LeftButton
    onClicked: {
      if (root.pluginApi?.mainInstance) {
        root.pluginApi.mainInstance.setActive(root.screen.name, root.widgetIndex);
      }
      root.pluginApi?.openPanel(root.screen);
    }
  }
```

(Requires `import qs.Services.Noctalia` for `DesktopWidgetRegistry`.)

**Step 4: Verify the full loop** — reload shell, exit edit mode, click the note. Expected: panel opens **with keyboard focus** (can type). Type "hello loop", Save. Expected: note text updates to "hello loop". Restart shell. Expected: note still shows "hello loop" (persisted in `Settings.data.desktopWidgets.monitorWidgets`). If focus or context fails, STOP and revisit AD-002/AD-003.

**Step 5: Commit** — `/git commit`

---

## Phase 2 — Markdown & rendering

### Task 5: Vendor markdown.js with a regression test

**Requirement:** REQ-004, C-006
**Files:**

- Create: `utils/markdown.js` (verbatim copy from sticky-notes)
- Create: `package.json` (devDependency vitest)
- Create: `tests/markdown.test.js`

**Step 1: Write the failing test first**

```js
import { describe, it, expect } from "vitest";
import { render } from "../utils/markdown.js";

describe("markdown.render", () => {
  it("renders bold", () => {
    expect(render("**hi**")).toContain("<b>hi</b>");
  });
  it("escapes raw HTML (XSS guard)", () => {
    const out = render("<script>alert(1)</script>");
    expect(out).not.toContain("<script>");
    expect(out).toContain("&lt;script&gt;");
  });
  it("returns empty string for empty input", () => {
    expect(render("")).toBe("");
  });
});
```

**Step 2: Run to verify it fails** — `npx vitest run`
Expected: FAIL with "Cannot find module '../utils/markdown.js'".

**Step 3: Vendor the implementation** — copy `sticky-notes/utils/markdown.js` verbatim into `utils/markdown.js`. Add to `package.json`:

```json
{ "name": "desktop-sticky-notes", "private": true, "type": "module",
  "scripts": { "test": "vitest run" },
  "devDependencies": { "vitest": "^2.0.0" } }
```

Note: `.pragma library` on line 1 is a valid JS comment-like directive but Vitest needs a named export. If the vendored file uses only `function render`, append `export { render };` guarded so QML's `.pragma library` import still works (QML imports by function name, not ESM).

**Step 4: Run to verify it passes** — `npm install && npx vitest run`
Expected: PASS (3 tests).

**Step 5: Commit** — `/git commit`

---

### Task 6: DesktopWidget renders Markdown as RichText

**Requirement:** REQ-004
**Files:**

- Modify: `DesktopWidget.qml`

**Step 1: Replace the placeholder `NText` with a scrollable RichText preview**

```qml
import "utils/markdown.js" as Markdown
// ...
Flickable {
  anchors.fill: parent
  anchors.margins: Math.round(Style.marginM * root.widgetScale)
  contentHeight: preview.implicitHeight
  clip: true
  TextArea {
    id: preview
    width: parent.width
    text: Markdown.render(root.noteText, { noteColor: root.noteBg })
    textFormat: TextEdit.RichText
    color: root.noteTextColor
    font.pointSize: Math.round(root.noteFontSize * root.widgetScale)
    wrapMode: TextArea.Wrap
    readOnly: true
    background: Item {}
    onLinkActivated: (link) => Qt.openUrlExternally(link)
  }
}
```

Add properties: `readonly property color noteTextColor: widgetData?.textColor ?? "#37474F"` and `readonly property int noteFontSize: widgetData?.fontSize ?? 14`.

**Step 2: Verify** — reload, set a note's text (via spike panel) to `**bold** and _italic_`. Expected: rendered bold/italic in the note, scales with widgetScale, no errors.

**Step 3: Commit** — `/git commit`

---

## Phase 3 — Full editor

### Task 7: Full Panel editor (text edit/preview toggle, shortcuts)

**Requirement:** REQ-002, REQ-003
**Files:**

- Modify: `Panel.qml` (replace spike editor with full editor based on `sticky-notes/components/ExpandedNoteWindow.qml`)

**Step 1: Implement editor** — dialog centered, note-colored; `TextArea` editor + RichText preview toggle; `pencil`/`check` button; `Ctrl+S` and `Esc` save via `DesktopWidgetRegistry.updateWidgetData(store.activeScreenName, store.activeWidgetIndex, { text: editor.text })`; Copy/Cut/Paste/SelectAll/Undo/Redo shortcuts (see ExpandedNoteWindow). Load initial text from the active note's `widgetData` (read current `monitorWidgets` entry by index).

**Step 2: Verify** — reload, click note, edit multi-line Markdown, Ctrl+S. Expected: preview matches; note re-renders; reopening shows saved text. Esc also saves.

**Step 3: Commit** — `/git commit`

---

## Phase 4 — Persistence & multiple notes

### Task 8: Defaults, restore on restart, instance independence

**Requirement:** REQ-005, REQ-006
**Files:**

- Modify: `Main.qml` (seed defaults from `manifest.metadata.defaultSettings` on first load)
- Modify: `DesktopWidget.qml` (defensive fallbacks for missing `widgetData` fields)

**Step 1: Ensure each field falls back to default** — `text` -> "", `bgColor`/`textColor`/`fontSize` -> manifest defaults. New instances start blank with default color.

**Step 2: Verify** — add 3 notes, give each different text + color, restart shell. Expected: all 3 restore independently with correct position/scale/text/color. Editing note A never mutates B or C.

**Step 3: Commit** — `/git commit`

---

## Phase 5 — Customization

### Task 9: Background color palette (post-it)

**Requirement:** REQ-007
**Files:**

- Create: `tests/palette.test.js`
- Create: `utils/palette.js`
- Modify: `Panel.qml` (color swatch row)

**Step 1: Failing test for the palette helper**

```js
import { describe, it, expect } from "vitest";
import { PALETTE, isValidColor } from "../utils/palette.js";
describe("palette", () => {
  it("exposes at least 5 post-it colors as hex", () => {
    expect(PALETTE.length).toBeGreaterThanOrEqual(5);
    PALETTE.forEach(c => expect(c).toMatch(/^#[0-9A-Fa-f]{6}$/));
  });
  it("validates hex colors", () => {
    expect(isValidColor("#FFF9C4")).toBe(true);
    expect(isValidColor("red")).toBe(false);
  });
});
```

**Step 2: Run -> FAIL** — `npx vitest run` -> "Cannot find module '../utils/palette.js'".

**Step 3: Implement `utils/palette.js`**

```js
export const PALETTE = ["#FFF9C4","#C8E6C9","#F8BBD0","#BBDEFB","#FFE0B2","#E1BEE7","#CFD8DC"];
export function isValidColor(c){ return /^#[0-9A-Fa-f]{6}$/.test(c); }
```

**Step 4: Run -> PASS.** Then add a swatch row in `Panel.qml` iterating `PALETTE`; clicking a swatch sets and persists `bgColor`.

**Step 5: Commit** — `/git commit`

---

### Task 10: Text color picker

**Requirement:** REQ-008
**Files:**

- Modify: `Panel.qml` (add `NColorPicker` bound to `textColor`)

**Step 1: Add `NColorPicker`** — initial value from active note `textColor`; on change persist via `updateWidgetData({ textColor })`.

**Step 2: Verify** — change text color, confirm note text recolors and persists after restart.

**Step 3: Commit** — `/git commit`

---

### Task 11: Font size control

**Requirement:** REQ-009
**Files:**

- Modify: `Panel.qml` (add `NValueSlider` for `fontSize`, e.g. 10–28)

**Step 1: Add slider** — persists `fontSize` via `updateWidgetData({ fontSize })`; `DesktopWidget` preview already multiplies by `widgetScale`.

**Step 2: Verify** — adjust font size independent of scale; persists after restart.

**Step 3: Commit** — `/git commit`

---

### Task 12: DesktopWidgetSettings (context-menu customization)

**Requirement:** REQ-010
**Files:**

- Create: `DesktopWidgetSettings.qml` (adapted from `custom-sticker/DesktopWidgetSettings.qml`)

**Step 1: Implement** — `ColumnLayout` with `widgetSettings.data.*` for `bgColor`, `textColor`, `fontSize`, `showBackground`; `saveSettings()` calls `widgetSettings.save()`. (No text field here — text is owned by the Panel editor.)

**Step 2: Verify** — in edit mode, right-click note → Widget settings → change color/font; persists and matches Panel edits.

**Step 3: Commit** — `/git commit`

---

## Phase 6 — i18n & release assets

### Task 13: i18n (en + pt)

**Requirement:** REQ-011
**Files:**

- Create: `i18n/en.json`
- Create: `i18n/pt.json`

**Step 1: Extract all UI strings** to keys (editor hints, swatch tooltips, settings labels); replace literals with `pluginApi.tr("...")`.

**Step 2: Verify** — switch Noctalia language to pt; labels translate; missing-key fallback works.

**Step 3: Commit** — `/git commit`

---

### Task 14: Release assets (preview + README)

**Requirement:** REQ-012
**Files:**

- Create: `README.md`
- Create: `preview.png`

**Step 1: Write `README.md`** (English) — what it does, install (symlink or via plugin manager), usage (add via Desktop Widgets, click to edit), screenshot.

**Step 2: Capture `preview.png`** — a couple of notes on the desktop (use `niri` screenshot, crop).

**Step 3: Verify** — README renders; preview.png present and referenced.

**Step 4: Commit** — `/git commit`

---

## Out of scope (P3 / deferred)

- REQ-013 (global shortcut to create a new note) — revisit after MVP; likely needs a `Main.qml` IPC handler + niri keybind.
- Submit PR to `noctalia-plugins` registry — after local validation.
