import XCTest
@testable import CodexRateLimitTrayMac

final class RefreshSchedulerTests: XCTestCase {
    func testDefaultRefreshIntervalIsThirtySeconds() {
        XCTAssertEqual(RefreshScheduler.defaultInterval, 30)
    }
}
