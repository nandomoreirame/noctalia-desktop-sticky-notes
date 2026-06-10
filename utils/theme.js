.pragma library

// Invert a note's palette by swapping background and foreground (light note with
// dark text <-> dark note with light text). It is an involution: toggling twice
// restores the original. Drives the per-note dark/light toggle. QML JS library.
function invert(bgColor, textColor) {
  return {
    bgColor: textColor,
    textColor: bgColor
  };
}
