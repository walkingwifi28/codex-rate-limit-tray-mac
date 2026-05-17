import XCTest
@testable import CodexRateLimitTrayMac

@MainActor
final class LoginItemServiceTests: XCTestCase {
    func testToggleUsesInjectedService() {
        let service = FakeLoginItemService(isEnabled: false)
        let viewModel = LoginItemViewModel(service: service)

        viewModel.setEnabled(true)

        XCTAssertTrue(service.requestedValue == true)
        XCTAssertTrue(viewModel.isEnabled)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testToggleFailureRestoresServiceStateAndSetsMessage() {
        let service = FakeLoginItemService(isEnabled: false, shouldThrow: true)
        let viewModel = LoginItemViewModel(service: service)

        viewModel.setEnabled(true)

        XCTAssertFalse(viewModel.isEnabled)
        XCTAssertEqual(viewModel.errorMessage, "ログイン項目を更新できません")
    }
}

private final class FakeLoginItemService: LoginItemServicing {
    var isEnabled: Bool
    var shouldThrow: Bool
    var requestedValue: Bool?

    init(isEnabled: Bool, shouldThrow: Bool = false) {
        self.isEnabled = isEnabled
        self.shouldThrow = shouldThrow
    }

    func setEnabled(_ enabled: Bool) throws {
        requestedValue = enabled
        if shouldThrow {
            throw NSError(domain: "test", code: 1)
        }
        isEnabled = enabled
    }
}
