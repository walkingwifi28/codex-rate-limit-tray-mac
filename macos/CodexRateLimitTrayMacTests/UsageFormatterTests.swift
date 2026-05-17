import XCTest
@testable import CodexRateLimitTrayMac

final class UsageFormatterTests: XCTestCase {
    private let formatter = UsageFormatter()

    func testTitleIsJapaneseProductTitle() {
        XCTAssertEqual(formatter.title, "Codex レート制限")
    }

    func testRemainingPercentClampsUsedPercentIntoBounds() {
        XCTAssertEqual(UsageWindow(usedPercent: -25, resetAt: Date()).remainingPercent, 100)
        XCTAssertEqual(UsageWindow(usedPercent: 25.5, resetAt: Date()).remainingPercent, 74.5)
        XCTAssertEqual(UsageWindow(usedPercent: 125, resetAt: Date()).remainingPercent, 0)
    }

    func testDisplayPercentRoundsAwayFromZero() {
        XCTAssertEqual(formatter.displayPercent(for: UsageWindow(usedPercent: 25.5, resetAt: Date())), 75)
        XCTAssertEqual(formatter.displayPercent(for: UsageWindow(usedPercent: 25.6, resetAt: Date())), 74)
        XCTAssertEqual(formatter.displayPercent(for: UsageWindow(usedPercent: 99.5, resetAt: Date())), 1)
    }

    func testResetFormatsUseCurrentTimeZone() throws {
        let fiveHourReset = try makeDate(month: 5, day: 17, hour: 18, minute: 48)
        let weeklyReset = try makeDate(month: 5, day: 24, hour: 13, minute: 48)

        XCTAssertEqual(formatter.fiveHourResetString(for: fiveHourReset), "18:48")
        XCTAssertEqual(formatter.weekResetString(for: weeklyReset), "05/24 13:48")
    }

    func testDisplayRowsAlignLabelsAndIncludeRemainingPercentAndResetTimes() throws {
        let state = try makeState(
            fiveHourUsedPercent: 40,
            fiveHourReset: makeDate(month: 5, day: 17, hour: 18, minute: 48),
            weekUsedPercent: 6,
            weekReset: makeDate(month: 5, day: 24, hour: 13, minute: 48)
        )

        let rows = formatter.displayRows(for: state)

        XCTAssertEqual(rows, [
            "5時間 : 残り 60% 18:48",
            "週   : 残り 94% 05/24 13:48",
        ])
        XCTAssertEqual(rows[0].firstIndex(of: ":"), rows[1].firstIndex(of: ":"))
    }

    func testStatusSummaryUsesRoundedRemainingPercents() throws {
        let state = try makeState(
            fiveHourUsedPercent: 39.5,
            fiveHourReset: makeDate(month: 5, day: 17, hour: 18, minute: 48),
            weekUsedPercent: 6.4,
            weekReset: makeDate(month: 5, day: 24, hour: 13, minute: 48)
        )

        XCTAssertEqual(formatter.statusSummary(for: state), "Codexレート制限 : 61% / 94%")
    }

    private func makeState(
        fiveHourUsedPercent: Double,
        fiveHourReset: Date,
        weekUsedPercent: Double,
        weekReset: Date
    ) throws -> UsageState {
        UsageState.success(
            fiveHour: UsageWindow(usedPercent: fiveHourUsedPercent, resetAt: fiveHourReset),
            week: UsageWindow(usedPercent: weekUsedPercent, resetAt: weekReset)
        )
    }

    private func makeDate(month: Int, day: Int, hour: Int, minute: Int) throws -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = .current
        components.year = 2026
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0

        return try XCTUnwrap(components.date)
    }
}
