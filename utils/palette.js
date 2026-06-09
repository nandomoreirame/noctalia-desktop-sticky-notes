.pragma library

// Post-it style background palette + hex validation, shared by the editor Panel
// (and reused by the widget settings). Written as a QML JS library: bare
// top-level declarations are reached as Palette.PALETTE / Palette.isValidColor.
var PALETTE = ["#FFF9C4", "#C8E6C9", "#F8BBD0", "#BBDEFB", "#FFE0B2", "#E1BEE7", "#CFD8DC"];

function isValidColor(c) {
  return /^#[0-9A-Fa-f]{6}$/.test(c);
}
