import { describe, it, expect } from "vitest";
import { clampDimension, WIDTH_MIN, WIDTH_MAX, HEIGHT_MIN, HEIGHT_MAX } from "../utils/dimensions.js";

describe("clampDimension", () => {
  it("clamps below the minimum", () => {
    expect(clampDimension(50, 120, 600)).toBe(120);
  });

  it("clamps above the maximum", () => {
    expect(clampDimension(999, 120, 600)).toBe(600);
  });

  it("keeps an in-range value", () => {
    expect(clampDimension(300, 120, 600)).toBe(300);
  });
});

describe("dimension ranges", () => {
  it("exposes a sane width range", () => {
    expect(WIDTH_MIN).toBeLessThan(WIDTH_MAX);
  });

  it("exposes a sane height range", () => {
    expect(HEIGHT_MIN).toBeLessThan(HEIGHT_MAX);
  });
});
