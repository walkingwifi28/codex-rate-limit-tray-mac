# 5時間・1週間レート制限UI復元 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the macOS app's two-window rate-limit behavior and UI, with `primary_window` shown as 5-hour usage and `secondary_window` shown as weekly usage.

**Architecture:** Restore the pre-`5117315` data contract so `UsageState` owns `fiveHour` and `week`. The parser maps the API windows into that state, the formatter exposes two aligned rows, and the renderer draws the weekly outer ring plus the five-hour inner disc. Existing refresh, authentication, error, and scheduling flows remain unchanged.

**Tech Stack:** Swift, SwiftUI, AppKit, XCTest, Xcode project.

## Global Constraints

- Keep `primary_window` mapped to the 5-hour window and `secondary_window` mapped to the weekly window.
- Preserve the existing Japanese labels: `5時間`, `週`, `残り`, and `Codexレート制限`.
- Keep the weekly reset needle and the existing outer-ring geometry.
- Keep invalid/missing required API fields mapped to `UsageErrorKind.invalidResponse`.
- Do not add dependencies or change authentication, scheduling, or network endpoints.
- Run focused tests after each task and the full macOS XCTest suite before completion.

---

### Task 1: Restore the two-window state and parser contract

**Files:**
- Modify: `macos/CodexRateLimitTrayMac/Domain/UsageModels.swift`
- Modify: `macos/CodexRateLimitTrayMac/Domain/WhamUsageParser.swift`
- Modify: `macos/CodexRateLimitTrayMacTests/WhamUsageParserTests.swift`
- Modify: `macos/CodexRateLimitTrayMacTests/WhamUsageClientTests.swift`
- Modify: `macos/CodexRateLimitTrayMacTests/UsageViewModelTests.swift`

**Interfaces:**
- Produces `UsageState.fiveHour`, `UsageState.week`, and `UsageState.success(fiveHour:week:)` for the formatter and renderer tasks.
- `WhamUsageParser.parse(_:)` continues returning `Result<UsageState, UsageErrorKind>`.

- [ ] **Step 1: Add a failing parser test for the secondary-to-week mapping.**

Add this test to `WhamUsageParserTests` while the current one-window implementation is still present:

```swift
func testParsesSecondaryWindowAsWeeklyWindow() throws {
    let data = Data("""
    {
      "rate_limit": {
        "primary_window": { "used_percent": 25.5, "reset_at": 1715781600 },
        "secondary_window": { "used_percent": 80, "reset_at": 1716094800 }
      }
    }
    """.utf8)

    let state = try XCTUnwrap(WhamUsageParser().parse(data).successValue)

    XCTAssertEqual(state.week.usedPercent, 80)
    XCTAssertEqual(state.week.resetAt, Date(timeIntervalSince1970: 1_716_094_800))
}
```

- [ ] **Step 2: Run the focused parser test and verify the expected failure.**

Run:

```bash
xcodebuild test -scheme CodexRateLimitTrayMac -destination 'platform=macOS' -only-testing:CodexRateLimitTrayMacTests/WhamUsageParserTests/testParsesSecondaryWindowAsWeeklyWindow
```

Expected: the test runs but fails because the current parser still uses `primary_window` as `state.week`.

- [ ] **Step 3: Restore the two-window model and parser mapping.**

In `UsageModels.swift`, restore the `fiveHour` property and change the success factory to:

```swift
static func success(fiveHour: UsageWindow, week: UsageWindow) -> UsageState {
    UsageState(
        fiveHour: fiveHour,
        week: week,
        errorKind: .none,
        errorMessage: nil
    )
}
```

Also include an empty `fiveHour` window in `UsageState.error`. In `WhamUsageParser.swift`, decode both response windows and construct:

```swift
UsageState.success(
    fiveHour: UsageWindow(
        usedPercent: response.rateLimit.primaryWindow.usedPercent,
        resetAt: Date(timeIntervalSince1970: response.rateLimit.primaryWindow.resetAt)
    ),
    week: UsageWindow(
        usedPercent: response.rateLimit.secondaryWindow.usedPercent,
        resetAt: Date(timeIntervalSince1970: response.rateLimit.secondaryWindow.resetAt)
    )
)
```

Restore `secondaryWindow` in the private `RateLimit` decoding model. Update all test fixtures that construct `UsageState` to pass both windows, and update parser/client assertions so `primary_window` is asserted through `state.fiveHour` and `secondary_window` through `state.week`.

- [ ] **Step 4: Run parser and client tests and verify they pass.**

Run:

```bash
xcodebuild test -scheme CodexRateLimitTrayMac -destination 'platform=macOS' -only-testing:CodexRateLimitTrayMacTests/WhamUsageParserTests -only-testing:CodexRateLimitTrayMacTests/WhamUsageClientTests
```

Expected: all selected tests pass, including the missing/null secondary-window rejection behavior.

- [ ] **Step 5: Commit the state and parser restoration.**

```bash
git add macos/CodexRateLimitTrayMac/Domain/UsageModels.swift macos/CodexRateLimitTrayMac/Domain/WhamUsageParser.swift macos/CodexRateLimitTrayMacTests/WhamUsageParserTests.swift macos/CodexRateLimitTrayMacTests/WhamUsageClientTests.swift macos/CodexRateLimitTrayMacTests/UsageViewModelTests.swift
git commit -m "復元: 5時間と週次の使用量モデル"
```

### Task 2: Restore the two formatter rows and status summary

**Files:**
- Modify: `macos/CodexRateLimitTrayMac/Domain/UsageFormatter.swift`
- Modify: `macos/CodexRateLimitTrayMacTests/UsageFormatterTests.swift`

**Interfaces:**
- Consumes `UsageState.fiveHour` and `UsageState.week` from Task 1.
- Produces the existing `[UsageDisplayRow]` representation consumed by `MenuBarContentView`.

- [ ] **Step 1: Change the formatter test expectation to require both rows.**

Update the test fixture to construct separate five-hour and weekly windows, then expect:

```swift
[
    UsageDisplayRow(label: "5時間", separator: ":", remainingLabel: "残り", percentText: "94%", resetDateText: "", resetTimeText: "13:48"),
    UsageDisplayRow(label: "週", separator: ":", remainingLabel: "残り", percentText: "81%", resetDateText: "05/24", resetTimeText: "13:48"),
]
```

Also change the summary assertion to expect `Codexレート制限 : 94% / 81%`.

- [ ] **Step 2: Run the focused formatter tests and verify the expected failure.**

Run:

```bash
xcodebuild test -scheme CodexRateLimitTrayMac -destination 'platform=macOS' -only-testing:CodexRateLimitTrayMacTests/UsageFormatterTests
```

Expected: the tests fail because the current formatter returns only the weekly row and summary.

- [ ] **Step 3: Restore five-hour date/time formatting, rows, and summary.**

In `UsageFormatter.swift`:

- Restore `fiveHourResetFormatter` with the `HH:mm` format and the `fiveHourResetString(for:)` method.
- Return the five-hour row first with an empty date column and the five-hour reset time.
- Return the weekly row second with the existing `MM/dd` and `HH:mm` columns.
- Format the status summary from `state.fiveHour` followed by `state.week`, separated by ` / `.

- [ ] **Step 4: Run the focused formatter tests and verify they pass.**

Run the same `UsageFormatterTests` command from Step 2. Expected: all formatter tests pass with aligned two-row output.

- [ ] **Step 5: Commit the formatter restoration.**

```bash
git add macos/CodexRateLimitTrayMac/Domain/UsageFormatter.swift macos/CodexRateLimitTrayMacTests/UsageFormatterTests.swift
git commit -m "復元: 5時間と週次の使用量表示"
```

### Task 3: Restore the two-layer icon and appearance wiring

**Files:**
- Modify: `macos/CodexRateLimitTrayMac/Rendering/RateLimitIconRenderer.swift`
- Modify: `macos/CodexRateLimitTrayMac/Views/UsageGraphView.swift`
- Modify: `macos/CodexRateLimitTrayMac/AppState/UsageViewModel.swift`
- Modify: `macos/CodexRateLimitTrayMacTests/RateLimitIconRendererTests.swift`

**Interfaces:**
- Consumes both windows from `UsageState` and a `RateLimitIconRenderer.Appearance` value from SwiftUI.
- Preserves `renderIcon(state:now:appearance:size:)` and the explicit parameter overload used by renderer tests.

- [ ] **Step 1: Add a failing renderer test for the inner five-hour layer.**

After Task 1 has restored the two-window state, add a test that uses the current state-based renderer signature so the test compiles before the renderer is changed:

```swift
func testTwoWindowStateRendersFiveHourUsageInsideWeeklyRing() throws {
    let state = UsageState.success(
        fiveHour: UsageWindow(usedPercent: 40, resetAt: Date(timeIntervalSince1970: 1)),
        week: UsageWindow(usedPercent: 29, resetAt: Date(timeIntervalSince1970: 7 * 24 * 60 * 60))
    )
    let image = RateLimitIconRenderer().renderIcon(state: state, size: 64)

    let innerPixel = try image.pixelColor(x: 44, y: 39)
    XCTAssertGreaterThan(innerPixel.alphaComponent, 0.95)
}
```

- [ ] **Step 2: Run the focused renderer test and verify the expected failure.**

Run:

```bash
xcodebuild test -scheme CodexRateLimitTrayMac -destination 'platform=macOS' -only-testing:CodexRateLimitTrayMacTests/RateLimitIconRendererTests/testTwoWindowStateRendersFiveHourUsageInsideWeeklyRing
```

Expected: the test compiles against the restored two-window state but fails because the current renderer leaves the inner area transparent.

- [ ] **Step 3: Restore renderer appearance, parameters, and inner fill.**

In `RateLimitIconRenderer.swift`:

- Restore `Appearance.light` and `.dark`, mapping to the pre-existing inner-disc colors.
- Restore `lightBackground`, `lightInnerDisc`, `darkBackground`, and `darkInnerDisc` color constants.
- Add `fiveHourRemainingPercent` and `appearance` to the state and explicit render methods.
- Keep the weekly outer `fillPie`, then call `fillPie` again with `innerRadius: 0`, `radius: innerRadius`, `fiveHourRemainingPercent`, and `appearance.innerDiscColor.rgba`.
- Keep the weekly needle unchanged.

In `UsageGraphView.swift`, restore `@Environment(\.colorScheme)` and select `.dark` or `.light`. In `UsageViewModel.swift`, pass the current appearance during initial icon creation and refreshes, and restore the helper that reads `NSApp.effectiveAppearance`.

- [ ] **Step 4: Restore renderer tests for both appearance modes and run them.**

Restore the tests for light/dark inner colors, transparent center/outer pixels, separate inner/outer arcs, anti-aliasing, and weekly needle geometry. Run the full `RateLimitIconRendererTests` target and confirm all tests pass.

- [ ] **Step 5: Commit the icon and appearance restoration.**

```bash
git add macos/CodexRateLimitTrayMac/Rendering/RateLimitIconRenderer.swift macos/CodexRateLimitTrayMac/Views/UsageGraphView.swift macos/CodexRateLimitTrayMac/AppState/UsageViewModel.swift macos/CodexRateLimitTrayMacTests/RateLimitIconRendererTests.swift
git commit -m "復元: 5時間と週次の二重リング"
```

### Task 4: Full regression verification and cleanup

**Files:**
- Inspect: `macos/CodexRateLimitTrayMac/Services/WhamUsageClient.swift`
- Inspect: `macos/CodexRateLimitTrayMac/Views/MenuBarContentView.swift`
- Inspect: all files changed by Tasks 1–3

- [ ] **Step 1: Run the complete macOS XCTest suite.**

Run:

```bash
xcodebuild test -scheme CodexRateLimitTrayMac -destination 'platform=macOS'
```

Expected: the complete test suite passes with zero failures.

- [ ] **Step 2: Build the macOS app target.**

Run:

```bash
xcodebuild build -scheme CodexRateLimitTrayMac -destination 'platform=macOS'
```

Expected: the app target builds successfully.

- [ ] **Step 3: Check for stale single-window assumptions.**

Run:

```bash
rg -n "primary_window|secondary_window|fiveHour|5時間|secondaryWindow|UsageState\.success" macos/CodexRateLimitTrayMac macos/CodexRateLimitTrayMacTests
```

Confirm that parser, state, formatter, renderer, and tests consistently use both windows, while unrelated authentication and scheduling code remains unchanged.

- [ ] **Step 4: Inspect the final diff and status.**

Run:

```bash
git diff 5117315..HEAD --stat
git status --short
```

Confirm only the design/plan documentation and the requested dual-window restoration are present, with no generated build artifacts staged.
