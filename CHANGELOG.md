# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-10-09

First public release. Requires Noctalia Shell v4 (`noctalia-shell` 4.6.6 to 4.7.x,
tested on 4.7.7); Noctalia v5 is not supported.

### Added

- Pin sticky notes on the desktop as draggable, scalable Noctalia desktop widgets, each
  persisting its own text, colors, size, position and scale.
- Render note text as Markdown (bold, italic, code, lists, task lists, quotes, tables
  and links) as read-only rich text, with a font size that stays constant as the
  widget is scaled.
- Edit notes in a focused popup centered on screen, with an edit/preview toggle,
  `Ctrl+S`/`Esc` to save, clipboard shortcuts and auto-focused input.
- Customize each note from the editor: post-it background palette, text color, font
  size, independent width and height, and an inner padding (0-40 px).
- Optionally back a note with a Markdown file: the note reads and edits that `.md` file
  in place, creates it on first save and reflects external edits live. With no path the
  text is stored inline.
- Scroll long notes with the mouse wheel, with a scrollbar on the note.
- Toggle a per-note dark/light mode that inverts background and foreground and adapts
  the swatch palette and the Markdown quote, code and link colors.
- Customize background, text color and font size from the desktop widget context menu
  (edit mode).
- English and Portuguese translations.

### Credits

- The Markdown renderer and the editor layout come from the MIT `sticky-notes` plugin by
  sapjax (see `THIRD_PARTY.md`).

[0.1.0]: https://github.com/nandomoreirame/noctalia-desktop-sticky-notes/releases/tag/v0.1.0
