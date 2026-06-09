import { defineConfig } from "vitest/config";

// The files under utils/ are QML JavaScript libraries: they start with a
// `.pragma library` directive and expose bare top-level `function`/`var`
// declarations (QML reaches them as `Module.name` after `import "x.js" as Module`).
// Node/Vitest, however, needs ES module exports. To keep the on-disk files
// valid QML libraries (vendored verbatim, see AD-004/C-006) while still being
// testable, this plugin rewrites them at test time only: it strips the QML
// `.pragma`/`.import` directives and re-exports every top-level declaration.
function qmlLibraryToEsm() {
  return {
    name: "qml-library-to-esm",
    enforce: "pre",
    transform(code, id) {
      if (!/\/utils\/[^/]+\.js$/.test(id)) return null;

      let out = code
        .replace(/^[ \t]*\.pragma[ \t].*$/gm, "")
        .replace(/^[ \t]*\.import[ \t].*$/gm, "");

      const names = new Set();
      const re = /^(?:function|const|let|var)\s+([A-Za-z_$][\w$]*)/gm;
      let match;
      while ((match = re.exec(out)) !== null) {
        names.add(match[1]);
      }

      if (names.size > 0) {
        out += `\nexport { ${[...names].join(", ")} };\n`;
      }
      return { code: out, map: null };
    }
  };
}

export default defineConfig({
  plugins: [qmlLibraryToEsm()],
  test: {
    environment: "node"
  }
});
