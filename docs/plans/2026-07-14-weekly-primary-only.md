# Weekly Primary-Only Usage Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.
> **Goal:** Read the weekly Codex limit from `primary_window`, ignore `secondary_window`, and remove the obsolete five-hour UI.
> **Architecture:** Keep one `UsageWindow` in `UsageState` as the weekly window. The parser decodes only `primary_window`; JSON decoding continues to ignore the unused secondary field. The renderer draws one weekly ring and needle, while the formatter exposes one weekly row and summary.
> **Tech Stack:** Swift, SwiftUI, AppKit, XCTest, Xcode project.

## Task 1: Update parser and state contract

**Files:**
- Modify: `macos/CodexRateLimitTrayMac/Domain/WhamUsageParser.swift`
- Modify: `macos/CodexRateLimitTrayMac/Domain/UsageModels.swift`
- Test: `macos/CodexRateLimitTrayMacTests/WhamUsageParserTests.swift`

**Steps:**
1. Write a failing test proving `primary_window` becomes `state.week` and `secondary_window: null` is accepted.
2. Run the parser tests and confirm the new test fails because the existing model requires both windows.
3. Remove the five-hour state field and decode only the primary window into the weekly state.
4. Run the parser tests and confirm they pass.

## Task 2: Remove five-hour presentation and rendering

**Files:**
- Modify: `macos/CodexRateLimitTrayMac/Rendering/RateLimitIconRenderer.swift`
- Modify: `macos/CodexRateLimitTrayMac/Domain/UsageFormatter.swift`
- Modify: `macos/CodexRateLimitTrayMac/AppState/UsageViewModel.swift`
- Modify: `macos/CodexRateLimitTrayMacTests/RateLimitIconRendererTests.swift`
- Modify: `macos/CodexRateLimitTrayMacTests/UsageFormatterTests.swift`
- Modify: `macos/CodexRateLimitTrayMacTests/UsageViewModelTests.swift`

**Steps:**
1. Write failing tests requiring a single weekly row/ring and a transparent center.
2. Run focused tests and confirm they fail against the two-window UI.
3. Remove the inner disc, five-hour parameters, five-hour formatter text, and five-hour state setup.
4. Run focused tests and confirm they pass.

## Task 3: Regression verification

**Files:** None.

**Steps:**
1. Run the complete macOS XCTest suite.
2. Build the macOS target with the repository's Xcode project.
3. Inspect the diff for leftover five-hour/secondary usage and confirm only the requested behavior changed.
