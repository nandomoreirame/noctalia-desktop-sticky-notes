import { describe, it, expect } from "vitest";
import { PALETTE, isValidColor } from "../utils/palette.js";

describe("palette", () => {
  it("exposes at least 5 post-it colors as hex", () => {
    expect(PALETTE.length).toBeGreaterThanOrEqual(5);
    PALETTE.forEach(c => expect(c).toMatch(/^#[0-9A-Fa-f]{6}$/));
  });

  it("validates hex colors", () => {
    expect(isValidColor("#FFF9C4")).toBe(true);
    expect(isValidColor("red")).toBe(false);
  });
});
