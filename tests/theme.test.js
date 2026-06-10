import { describe, it, expect } from "vitest";
import { invert } from "../utils/theme.js";

describe("invert", () => {
  it("swaps background and foreground", () => {
    expect(invert("#FFF9C4", "#37474F")).toEqual({
      bgColor: "#37474F",
      textColor: "#FFF9C4"
    });
  });

  it("is its own inverse (toggling twice restores the original)", () => {
    const once = invert("#FFF9C4", "#37474F");
    const twice = invert(once.bgColor, once.textColor);
    expect(twice).toEqual({
      bgColor: "#FFF9C4",
      textColor: "#37474F"
    });
  });
});
