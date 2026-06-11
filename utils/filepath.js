.pragma library

// Pure path/text helpers for the optional file-backed note source.
// QML JS library: bare top-level functions are reached as FilePath.NAME after
// `import "utils/filepath.js" as FilePath`. No file I/O here (FileView does the
// actual read/write in QML). A vitest transform re-exports these for tests.

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
    return (fileContent !== undefined && fileContent !== null) ? fileContent : "";
  return (inlineText !== undefined && inlineText !== null) ? inlineText : "";
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
