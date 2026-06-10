import { describe, it, expect } from "vitest";
import { PALETTE, DARK_PALETTE, isValidColor, isDark, darken, markdownTheme } from "../utils/palette.js";

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

describe("isDark", () => {
  it("detects a dark color", () => {
    expect(isDark("#000000")).toBe(true);
    expect(isDark("#37474F")).toBe(true);
  });

  it("detects a light color", () => {
    expect(isDark("#FFF9C4")).toBe(false);
    expect(isDark("#FFFFFF")).toBe(false);
  });
});

describe("darken", () => {
  it("darkens a color toward black", () => {
    expect(darken("#FFFFFF", 0.5)).toBe("#808080");
  });

  it("keeps the #rrggbb format", () => {
    expect(darken("#FFF9C4", 0.32)).toMatch(/^#[0-9a-f]{6}$/);
  });
});

describe("DARK_PALETTE", () => {
  it("mirrors the light palette length", () => {
    expect(DARK_PALETTE.length).toBe(PALETTE.length);
  });

  it("is entirely dark", () => {
    DARK_PALETTE.forEach(c => expect(isDark(c)).toBe(true));
  });
});

describe("markdownTheme", () => {
  it("passes the background through as a string noteColor", () => {
    expect(markdownTheme("#FFF9C4", "#37474F").noteColor).toBe("#FFF9C4");
  });

  it("uses the note's text color for quote text", () => {
    expect(markdownTheme("#000000", "#FFFFFF").quoteFg).toBe("#FFFFFF");
  });

  it("adapts link/code colors for dark vs light mode", () => {
    const dark = markdownTheme("#000000", "#FFFFFF");
    const light = markdownTheme("#FFF9C4", "#37474F");
    expect(dark.linkColor).not.toBe(light.linkColor);
    expect(dark.inlineCodeBg).not.toBe(light.inlineCodeBg);
  });
});
