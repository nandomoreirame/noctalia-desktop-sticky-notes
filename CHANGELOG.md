# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Changed

- Credit the MIT `sticky-notes` plugin for the vendored Markdown renderer and the editor layout (`THIRD_PARTY.md`).
- The README states Noctalia v4 support (tested on 4.7.7) and the planned v5 port.

## [0.3.0] - 2026-06-11

### Added

- Optionally back a note with a Markdown file: set a `.md` file path in the widget settings and the note reads and edits that file in place, creating it on first save and reflecting external edits live. Leave the path empty to keep storing the note's text inline (backward compatible).

## [0.2.0] - 2026-06-10

### Added

- Add an inner padding control to the editor that sets the spacing between a note's edge and its content (0-40 px, scaled with the widget).

## [0.1.0] - 2026-06-10

### Added

- Pin sticky notes on the desktop as draggable, scalable Noctalia desktop widgets, each persisting its own text, colors, size, position and scale.
- Render note text as Markdown (bold, italic, code, lists, task lists, quotes, tables and links) as read-only rich text, with a font size that stays constant as the widget is scaled.
- Edit notes in a focused popup that opens centered on screen, with an edit/preview toggle, `Ctrl+S`/`Esc` to save, clipboard shortcuts and auto-focused input.
- Customize each note from the editor: post-it background palette, text color, font size, and independent width and height.
- Scroll long notes with the mouse wheel, with a scrollbar indicator on the note.
- Toggle a per-note dark/light mode that inverts background and foreground, switches the swatch palette to darker tones, adapts the Markdown quote, code and link colors, and shows a sun/moon indicator.
- Customize background, text color and font size from the desktop widget context menu (edit mode).
- Provide English and Portuguese translations.

[0.3.0]: https://github.com/nandomoreirame/noctalia-desktop-sticky-notes/releases/tag/v0.3.0
[0.2.0]: https://github.com/nandomoreirame/noctalia-desktop-sticky-notes/releases/tag/v0.2.0
[0.1.0]: https://github.com/nandomoreirame/noctalia-desktop-sticky-notes/releases/tag/v0.1.0
