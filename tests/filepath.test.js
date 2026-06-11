import { describe, it, expect } from "vitest";
import * as FilePath from "../utils/filepath.js";

describe("expandPath", () => {
  it("returns empty for empty/whitespace", () => {
    expect(FilePath.expandPath("", "/home/me")).toBe("");
    expect(FilePath.expandPath("   ", "/home/me")).toBe("");
  });
  it("trims surrounding whitespace", () => {
    expect(FilePath.expandPath("  /a/b.md  ", "/home/me")).toBe("/a/b.md");
  });
  it("expands a leading ~ to home", () => {
    expect(FilePath.expandPath("~/notes/x.md", "/home/me")).toBe("/home/me/notes/x.md");
    expect(FilePath.expandPath("~", "/home/me")).toBe("/home/me");
  });
  it("does not expand ~ in the middle", () => {
    expect(FilePath.expandPath("/a/~/b.md", "/home/me")).toBe("/a/~/b.md");
  });
});

describe("resolveNoteText", () => {
  it("uses file content when linked", () => {
    expect(FilePath.resolveNoteText("/a.md", "FILE", "INLINE")).toBe("FILE");
  });
  it("uses inline text when not linked", () => {
    expect(FilePath.resolveNoteText("", "FILE", "INLINE")).toBe("INLINE");
    expect(FilePath.resolveNoteText("   ", "FILE", "INLINE")).toBe("INLINE");
  });
  it("linked but empty file yields empty string (shows hint)", () => {
    expect(FilePath.resolveNoteText("/a.md", "", "INLINE")).toBe("");
  });
});

describe("isLinked", () => {
  it("true only for a non-empty trimmed path", () => {
    expect(FilePath.isLinked("/a.md")).toBe(true);
    expect(FilePath.isLinked("")).toBe(false);
    expect(FilePath.isLinked("  ")).toBe(false);
  });
});

describe("fileName", () => {
  it("returns the basename", () => {
    expect(FilePath.fileName("/a/b/notes.md")).toBe("notes.md");
    expect(FilePath.fileName("notes.md")).toBe("notes.md");
    expect(FilePath.fileName("")).toBe("");
    expect(FilePath.fileName("/a/b/")).toBe("");
  });
});
