.pragma library

// Clamp a proposed scroll offset to the valid range [0, contentHeight - viewportHeight].
// Returns 0 when the content fits the viewport. Used to drive the note widget's
// wheel scrolling without letting it overscroll. Written as a QML JS library.
function clampScroll(offset, contentHeight, viewportHeight) {
  var max = Math.max(0, contentHeight - viewportHeight);
  if (offset < 0)
    return 0;
  if (offset > max)
    return max;
  return offset;
}
