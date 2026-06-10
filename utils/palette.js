.pragma library

// Post-it style background palette + hex validation, shared by the editor Panel
// (and reused by the widget settings). Written as a QML JS library: bare
// top-level declarations are reached as Palette.PALETTE / Palette.isValidColor.
var PALETTE = ["#FFF9C4", "#C8E6C9", "#F8BBD0", "#BBDEFB", "#FFE0B2", "#E1BEE7", "#CFD8DC"];

function isValidColor(c) {
  return /^#[0-9A-Fa-f]{6}$/.test(c);
}

// Perceived luminance (0-255) of a #rrggbb color, used to tell whether a note is
// in "dark mode" (its background is dark).
function luminance(hex) {
  var r = parseInt(hex.substr(1, 2), 16);
  var g = parseInt(hex.substr(3, 2), 16);
  var b = parseInt(hex.substr(5, 2), 16);
  return 0.299 * r + 0.587 * g + 0.114 * b;
}

function isDark(hex) {
  return luminance(hex) < 128;
}

// Multiply each channel toward black (factor in 0..1) and return a #rrggbb string.
function darken(hex, factor) {
  function ch(i) {
    var v = Math.round(parseInt(hex.substr(i, 2), 16) * factor);
    if (v < 0)
      v = 0;
    if (v > 255)
      v = 255;
    var s = v.toString(16);
    return s.length === 1 ? "0" + s : s;
  }
  return "#" + ch(1) + ch(3) + ch(5);
}

// Darkened post-it palette, shown in the swatch row when the note is in dark mode.
var DARK_PALETTE = PALETTE.map(function (c) {
  return darken(c, 0.32);
});

// Theme object for markdown.js render(). Passing the background as a hex STRING
// (not a QML color object) is required so the parser can derive the quote
// background; quote/code/link colors adapt to the note's dark/light mode.
function markdownTheme(bgHex, fgHex) {
  var dark = isDark(bgHex);
  return {
    "noteColor": bgHex,
    "quoteFg": fgHex,
    "quoteBorder": dark ? "#5C6BC0" : "#83B4ED",
    "inlineCodeBg": dark ? "#2E2E2E" : "#ECEFF1",
    "inlineCodeFg": dark ? "#F48FB1" : "#D81B60",
    "linkColor": dark ? "#82B1FF" : "#1565C0"
  };
}
