# Spec: note file source (link a note to a `.md` file)

- **Date:** 2026-06-11
- **Status:** validated (research complete)
- **Type:** feature for the desktop-sticky-notes Noctalia plugin
- **Builds on:** `docs/specs/2026-06-09-desktop-sticky-notes.md` (MVP, v0.2.0)

## 1. Vision

A note can optionally be backed by a `.md` file on disk. When a `filePath` is set,
that file becomes the single source of truth for the note's text: the widget reads
and renders the file, and the editor writes back into it. With no `filePath`, the
note keeps the current inline behavior (text in `widgetData.text`). This is fully
backward compatible: existing notes are unaffected.

User intent: "add a `.md` file path and the sticky note automatically reads and
edits that file (basically swap the database of a single sticker)".

Research decisions (collected from the user):

1. **Where to configure:** in the **Widget Settings** context menu (`DesktopWidgetSettings.qml`).
2. **External sync:** live watch (`watchChanges`) so external edits reflect in real time.
3. **Missing file:** allow linking; create the file on first save.
4. **Linking a non-empty file:** the file content wins; the note reflects the file.

## 2. Architecture

```
DesktopWidget.qml          # reads the file via FileView (watch, read-only); render uses file content when linked
DesktopWidgetSettings.qml  # NEW: file path field + NFilePicker + clear/unlink button
Panel.qml                  # writes the file via FileView (atomicWrites, no watch) when the note is linked
Main.qml                   # store gains activeFilePath
utils/filepath.js          # NEW: expandPath / resolveNoteText / isLinked / fileName (pure JS, TDD)
i18n/en.json, i18n/pt.json # NEW keys for the file source settings
manifest.json              # defaultSettings gains defaultFilePath ""
```

### AD-005: `filePath` lives in `widgetData` (per-instance pointer)

The link is an optional `filePath` string in `widgetData`, persisted per instance
through the same storage as every other note property:
`widgetSettings.data.filePath = path; widgetSettings.save()` in the settings menu,
which writes into `Settings.data.desktopWidgets.monitorWidgets[].widgets[index]`
(same registry as `updateWidgetData`, confirmed in `DraggableDesktopWidget.qml:147`).
Empty/absent `filePath` = inline mode (current behavior).

### AD-006: Reading happens in the widget (FileView, watch, read-only)

`DesktopWidget.qml` holds a `FileView` (`Quickshell.Io`) whose `path` is the note's
`filePath`. It is **read-only** (never calls `setText`) so its own `watchChanges: true`
never self-triggers a reload loop. A reactive `fileContent` string is refreshed in
`onLoaded` and `onFileChanged` (`fileContent = view.text()`); `onLoadFailed(error)`
with `error === 2` (file not found) leaves `fileContent` empty (note shows the hint).
The rendered text is `resolveNoteText(filePath, fileContent, widgetData.text)`.

### AD-007: Writing happens in the editor (FileView, atomicWrites, no watch)

`Panel.qml` holds a `FileView` with `watchChanges: false` and `atomicWrites: true`.
On save:

- linked note (`activeFilePath` non-empty): `fileView.path = activeFilePath; fileView.setText(editor.text)` (creates the file on first write).
- inline note: `persist({ text: editor.text })` (current behavior).

Because the editor's FileView does not watch, it never reloads on its own writes.
The widget, watching the same path, receives `onFileChanged` and re-renders. The
editor does not watch while open, so a concurrent external edit is resolved
last-write-wins on save (documented limitation).

### AD-008: Path/text logic is pure and unit-tested

`utils/filepath.js` is a QML `.pragma library` (reachable as `FilePath.NAME`) with:

- `expandPath(path, home)` -> trims, expands a leading `~` to `home`, returns `""` for empty/whitespace.
- `resolveNoteText(filePath, fileContent, inlineText)` -> `fileContent` when `filePath` is non-empty, else `inlineText`.
- `isLinked(filePath)` -> boolean (non-empty after trim).
- `fileName(path)` -> the basename for display in the settings menu.

Tested with Vitest (TDD), same transform setup as the other `utils/*.js`.

## 3. Requirements

### REQ-010 (P1): Configure / clear the file path

WHEN the user opens a note's Widget Settings, THEN they SHALL be able to set a
`.md` file path (editable text field + `NFilePicker` button) and clear it
(unlink button). Setting/clearing persists via `widgetSettings.data.filePath` +
`save()`.

### REQ-011 (P1): Widget renders the file when linked

WHEN a note has a non-empty `filePath`, THEN the widget SHALL render the file's
content instead of `widgetData.text`. WHEN the file does not exist or is empty,
THEN the note SHALL show the empty-state hint.

### REQ-012 (P1): Editing a linked note writes the file

WHEN a linked note is edited and saved, THEN the editor SHALL write the text into
the `.md` file, creating it on first save if missing. WHEN a note is not linked,
THEN it SHALL keep saving inline into `widgetData.text`.

### REQ-013 (P2): Live external sync

WHEN the linked file changes on disk (external editor), THEN the note's render
SHALL update in real time via `FileView.watchChanges`.

### REQ-014 (P2): File content wins on link

WHEN the user links a file that already has content, THEN the note SHALL reflect
the file's content. The inline `widgetData.text` SHALL be preserved (not erased)
and reactivated if the note is later unlinked.

### REQ-015 (P1): Input validation / safety

The file path is user input. The plugin SHALL expand a leading `~` to `$HOME` and
trim the path before use. File content (external, untrusted) SHALL continue to pass
through `markdown.js` `escapeHtml` before being rendered as RichText (existing XSS
guard, C-005). `FileView` uses the path directly (no shell), so there is no shell
injection vector.

## 4. Constraints

- **C-007:** Path/text resolution logic lives in `utils/filepath.js` (pure, TDD). No file I/O in the JS lib.
- **C-008:** The widget's `FileView` is read-only + watch; the editor's `FileView` writes with `atomicWrites: true` and `watchChanges: false`. This split avoids self-triggered reload loops.
- **C-009:** Backward compatible. A missing/empty `filePath` reproduces v0.2.0 behavior exactly. No migration of existing notes.
- **C-010:** Linked notes that exceed the existing color/font/scroll features keep all of them working (the file only replaces the text source, not the styling).

## 5. Out of scope

- Multiple notes editing the same file with conflict merge (last-write-wins only).
- File history / undo beyond the editor's in-session undo.
- Creating missing parent directories (save assumes the directory exists).
- Re-rendering the editor live while it is open and the file changes externally.

## 6. Verification

- **JS:** Vitest for `utils/filepath.js` (expandPath edge cases, resolveNoteText, isLinked, fileName). All prior tests stay green.
- **QML:** `qmllint` clean on changed files.
- **Runtime checklist (manual):**
  1. Link a note to an existing `.md` -> note shows the file content.
  2. Edit + save -> file on disk updated; widget re-renders.
  3. Link a path that does not exist -> empty hint; first save creates the file.
  4. Edit the file in another editor -> note updates live.
  5. Clear the path -> note reverts to its preserved inline text.
  6. A non-linked note behaves exactly as before.
