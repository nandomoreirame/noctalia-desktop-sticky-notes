.pragma library

// Base note dimensions (in px, before widgetScale is applied). The widget's
// uniform corner-scale still multiplies these, so width and height are set
// independently here and scaled together by the base class. Written as a QML JS
// library: bare top-level declarations are reached as Dimensions.NAME.
var WIDTH_MIN = 120;
var WIDTH_MAX = 600;
var HEIGHT_MIN = 80;
var HEIGHT_MAX = 600;

// Defensive clamp for a persisted dimension value (guards corrupt/out-of-range data).
function clampDimension(value, min, max) {
  if (value < min)
    return min;
  if (value > max)
    return max;
  return value;
}
