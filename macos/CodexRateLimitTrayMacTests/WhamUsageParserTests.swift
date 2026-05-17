import XCTest
@testable import CodexRateLimitTrayMac

final class WhamUsageParserTests: XCTestCase {
    func testParsesPrimaryAsFiveHourAndSecondaryAsWeek() throws {
        let data = Data("""
        {
          "rate_limit": {
            "primary_window": { "used_percent": 25.5, "reset_at": 1715781600 },
            "secondary_window": { "used_percent": 80, "reset_at": 1716094800 }
          }
        }
        """.utf8)

        let state = try XCTUnwrap(WhamUsageParser().parse(data).successValue)

        XCTAssertEqual(state.fiveHour.usedPercent, 25.5)
        XCTAssertEqual(state.fiveHour.resetAt, Date(timeIntervalSince1970: 1_715_781_600))
        XCTAssertEqual(state.week.usedPercent, 80)
        XCTAssertEqual(state.week.resetAt, Date(timeIntervalSince1970: 1_716_094_800))
    }

    func testInvalidJSONReturnsInvalidResponse() {
        let result = WhamUsageParser().parse(Data("{".utf8))

        XCTAssertEqual(result.failureValue, .invalidResponse)
    }

    func testMissingFieldsReturnsInvalidResponse() {
        let data = Data(#"{"rate_limit":{"primary_window":{"used_percent":25.5,"reset_at":1715781600}}}"#.utf8)

        let result = WhamUsageParser().parse(data)

        XCTAssertEqual(result.failureValue, .invalidResponse)
    }
}

private extension Result where Success == UsageState, Failure == UsageErrorKind {
    var successValue: UsageState? {
        if case let .success(value) = self {
            return value
        }
        return nil
    }

    var failureValue: UsageErrorKind? {
        if case let .failure(value) = self {
            return value
        }
        return nil
    }
}
