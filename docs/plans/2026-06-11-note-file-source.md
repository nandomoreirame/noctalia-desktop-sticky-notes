# Plan: note file source (link a note to a `.md` file)

- **Spec:** `docs/specs/2026-06-11-note-file-source.md`
- **Date:** 2026-06-11
- **Strategy:** sequential (QML files are interdependent; only the JS lib is unit-testable)
- **Tests:** Vitest for `utils/filepath.js`; `qmllint` for QML; runtime checklist for behavior.

## Task 1 (TDD): `utils/filepath.js` — pure path/text logic [REQ-015, AD-008, C-007]

**Files:** create `tests/filepath.test.js`, create `utils/filepath.js`.

**Step 1 — failing test (`tests/filepath.test.js`):**

```js
import { describe, it, expect } from "vitest";
import * as FilePath from "../utils/filepath.js";

describe("expandPath", () => {
  it("returns empty for empty/whitespace", () => {
    expect(FilePath.expandPath("", "/home/me")).toBe("");
    expect(FilePath.expandPath("   ", "/home/me")).toBe("");
  });
  it("trims surrounding whitespace", () => {
    expect(FilePath.expandPath("  /a/b.md  ", "/home/me")).toBe("/a/b.md");
  });
  it("expands a leading ~ to home", () => {
    expect(FilePath.expandPath("~/notes/x.md", "/home/me")).toBe("/home/me/notes/x.md");
    expect(FilePath.expandPath("~", "/home/me")).toBe("/home/me");
  });
  it("does not expand ~ in the middle", () => {
    expect(FilePath.expandPath("/a/~/b.md", "/home/me")).toBe("/a/~/b.md");
  });
});

describe("resolveNoteText", () => {
  it("uses file content when linked", () => {
    expect(FilePath.resolveNoteText("/a.md", "FILE", "INLINE")).toBe("FILE");
  });
  it("uses inline text when not linked", () => {
    expect(FilePath.resolveNoteText("", "FILE", "INLINE")).toBe("INLINE");
    expect(FilePath.resolveNoteText("   ", "FILE", "INLINE")).toBe("INLINE");
  });
  it("linked but empty file yields empty string (shows hint)", () => {
    expect(FilePath.resolveNoteText("/a.md", "", "INLINE")).toBe("");
  });
});

describe("isLinked", () => {
  it("true only for a non-empty trimmed path", () => {
    expect(FilePath.isLinked("/a.md")).toBe(true);
    expect(FilePath.isLinked("")).toBe(false);
    expect(FilePath.isLinked("  ")).toBe(false);
  });
});

describe("fileName", () => {
  it("returns the basename", () => {
    expect(FilePath.fileName("/a/b/notes.md")).toBe("notes.md");
    expect(FilePath.fileName("notes.md")).toBe("notes.md");
    expect(FilePath.fileName("")).toBe("");
    expect(FilePath.fileName("/a/b/")).toBe("");
  });
});
```

Run: `npx vitest run tests/filepath.test.js` -> RED (module missing).

**Step 3 — implement (`utils/filepath.js`):**

```js
.pragma library

// Pure path/text helpers for the optional file-backed note source.
// QML JS library: bare top-level functions are reached as FilePath.NAME.
// No file I/O here (FileView does the actual read/write in QML).

function expandPath(path, home) {
  if (!path)
    return "";
  var p = String(path).trim();
  if (p === "")
    return "";
  if (p === "~")
    return home;
  if (p.indexOf("~/") === 0)
    return home + p.substring(1);
  return p;
}

// File content wins when the note is linked (non-empty path), else inline text.
function resolveNoteText(filePath, fileContent, inlineText) {
  if (isLinked(filePath))
    return fileContent !== undefined && fileContent !== null ? fileContent : "";
  return inlineText !== undefined && inlineText !== null ? inlineText : "";
}

function isLinked(filePath) {
  return !!filePath && String(filePath).trim() !== "";
}

function fileName(path) {
  if (!path)
    return "";
  var p = String(path);
  var i = p.lastIndexOf("/");
  return i >= 0 ? p.substring(i + 1) : p;
}
```

Run: `npx vitest run` -> GREEN (all suites).

## Task 2: `Main.qml` store — `activeFilePath` [REQ-012, AD-005]

**File:** modify `Main.qml`.

Add `property string activeFilePath: ""` next to the other `active*` props, and in
`setActive(...)` set `activeFilePath = d.filePath || ""`. This carries the clicked
note's link into the shared editor.

## Task 3: `DesktopWidget.qml` — read the file (FileView, watch, read-only) [REQ-011, REQ-013, REQ-014, AD-006]

**File:** modify `DesktopWidget.qml`.

1. `import Quickshell.Io` and `import "utils/filepath.js" as FilePath`.
2. New props:
   ```qml
   readonly property string noteFilePath: FilePath.expandPath(widgetData?.filePath ?? "", Quickshell.env("HOME") || "")
   property string fileContent: ""
   readonly property bool linked: FilePath.isLinked(noteFilePath)
   ```
   (`import Quickshell` is already transitively available via the base class; add it explicitly.)
3. Replace `noteText` with the resolver:
   ```qml
   readonly property string noteText: FilePath.resolveNoteText(noteFilePath, fileContent, widgetData?.text ?? "")
   ```
4. Add the read-only watcher (creates nothing, only reads):
   ```qml
   FileView {
     id: noteFile
     path: root.linked ? root.noteFilePath : ""
     watchChanges: root.linked
     printErrors: false
     onLoaded: root.fileContent = noteFile.text()
     onFileChanged: { noteFile.reload(); root.fileContent = noteFile.text(); }
     onLoadFailed: function(error) { root.fileContent = ""; }
   }
   ```
5. In the click handler `setActive(...)`, add `"filePath": root.noteFilePath` to the snapshot
   and pass `text: root.noteText` (so a linked note hands the file content to the editor).

Verify: `qmllint DesktopWidget.qml` (ignore `qs.*` import noise).

## Task 4: `Panel.qml` — write the file when linked (FileView, atomicWrites) [REQ-012, AD-007]

**File:** modify `Panel.qml`.

1. `import Quickshell.Io` and `import "utils/filepath.js" as FilePath`.
2. `readonly property string activeFilePath: store?.activeFilePath ?? ""`.
3. Writer FileView (no watch, atomic):
   ```qml
   FileView {
     id: noteWriter
     watchChanges: false
     atomicWrites: true
     printErrors: false
   }
   ```
4. Rewrite `saveText()` to branch on the link:
   ```qml
   function saveText() {
     if (FilePath.isLinked(root.activeFilePath)) {
       noteWriter.path = root.activeFilePath;
       noteWriter.setText(editor.text);
     } else {
       persist({ "text": editor.text });
     }
   }
   ```

Verify: `qmllint Panel.qml`.

## Task 5: `DesktopWidgetSettings.qml` — path field + picker + clear [REQ-010]

**File:** modify `DesktopWidgetSettings.qml`.

1. `import QtQuick.Controls`, `import qs.Services.System`, `import "utils/filepath.js" as FilePath`.
2. New tracked prop + persist:
   ```qml
   property string filePath: widgetSettings?.data?.filePath ?? ""
   ```
   In `saveSettings()` add `widgetSettings.data.filePath = filePath;` before `save()`.
3. UI block (a labeled row): an `NTextInput` bound to `filePath` (placeholder `~/notes/todo.md`),
   an `NIconButton` (`icon: "wallpaper-selector"` or a folder icon) opening an `NFilePicker`
   (`selectionMode: "files"`, `nameFilters: ["*.md", "*.markdown", "*.txt"]`), and a clear
   `NIconButton` (`icon: "close"`) that sets `filePath = ""` and saves.
   ```qml
   ColumnLayout {
     Layout.fillWidth: true
     spacing: Style.marginS
     NLabel {
       label: root.pluginApi?.tr("settings.file-source-label") ?? "Markdown file"
       description: root.pluginApi?.tr("settings.file-source-description") ?? "Back this note with a .md file. Leave empty to store the text inline."
     }
     RowLayout {
       Layout.fillWidth: true
       spacing: Style.marginS
       NTextInput {
         Layout.fillWidth: true
         text: root.filePath
         placeholderText: "~/notes/todo.md"
         onEditingFinished: { root.filePath = text; root.saveSettings(); }
       }
       NIconButton {
         icon: "wallpaper-selector"
         tooltipText: root.pluginApi?.tr("settings.file-source-pick") ?? "Choose a file"
         onClicked: filePicker.openFilePicker()
       }
       NIconButton {
         icon: "close"
         enabled: FilePath.isLinked(root.filePath)
         tooltipText: root.pluginApi?.tr("settings.file-source-clear") ?? "Unlink file"
         onClicked: { root.filePath = ""; root.saveSettings(); }
       }
     }
     NFilePicker {
       id: filePicker
       selectionMode: "files"
       nameFilters: ["*.md", "*.markdown", "*.txt"]
       title: root.pluginApi?.tr("settings.file-source-label") ?? "Markdown file"
       onAccepted: paths => { if (paths.length > 0) { root.filePath = paths[0]; root.saveSettings(); } }
     }
   }
   ```

Verify: `qmllint DesktopWidgetSettings.qml`.

## Task 6: `manifest.json` default + i18n keys [REQ-010]

**Files:** modify `manifest.json`, `i18n/en.json`, `i18n/pt.json`.

- `manifest.json`: add `"defaultFilePath": ""` to `metadata.defaultSettings`.
- `i18n/en.json` `settings`:
  ```json
  "file-source-label": "Markdown file",
  "file-source-description": "Back this note with a .md file. Leave empty to store the text inline.",
  "file-source-pick": "Choose a file",
  "file-source-clear": "Unlink file"
  ```
- `i18n/pt.json` `settings` (mirror keys, pt-BR):
  ```json
  "file-source-label": "Arquivo Markdown",
  "file-source-description": "Vincule esta nota a um arquivo .md. Deixe vazio para guardar o texto embutido.",
  "file-source-pick": "Escolher arquivo",
  "file-source-clear": "Desvincular arquivo"
  ```
  (Mirror every existing `settings.*` key already present in en.json into pt.json.)

Validate JSON: `python3 -m json.tool manifest.json i18n/en.json i18n/pt.json`.

## Task 7: Verification + docs

- `npx vitest run` -> all green (prior + filepath).
- `qmllint` on all changed QML (ignore `qs.*` import noise).
- Update `README.md` (a "File-backed notes" bullet) and `docs/STATE.md`.

## Requirement coverage

| REQ | Tasks |
|-----|-------|
| REQ-010 | 5, 6 |
| REQ-011 | 1, 3 |
| REQ-012 | 2, 4 |
| REQ-013 | 3 |
| REQ-014 | 1, 3 |
| REQ-015 | 1, 3 |
