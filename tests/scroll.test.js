import { describe, it, expect } from "vitest";
import { clampScroll } from "../utils/scroll.js";

describe("clampScroll", () => {
  it("clamps to 0 at the top", () => {
    expect(clampScroll(-50, 300, 100)).toBe(0);
  });

  it("clamps to the max offset at the bottom", () => {
    expect(clampScroll(999, 300, 100)).toBe(200);
  });

  it("keeps an offset that is within range", () => {
    expect(clampScroll(120, 300, 100)).toBe(120);
  });

  it("returns 0 when the content fits the viewport", () => {
    expect(clampScroll(50, 80, 100)).toBe(0);
  });
});
