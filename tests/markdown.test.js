import { describe, it, expect } from "vitest";
import { render } from "../utils/markdown.js";

describe("markdown.render", () => {
  it("renders bold", () => {
    expect(render("**hi**")).toContain("<b>hi</b>");
  });

  it("escapes raw HTML (XSS guard)", () => {
    const out = render("<script>alert(1)</script>");
    expect(out).not.toContain("<script>");
    expect(out).toContain("&lt;script&gt;");
  });

  it("returns empty string for empty input", () => {
    expect(render("")).toBe("");
  });
});
