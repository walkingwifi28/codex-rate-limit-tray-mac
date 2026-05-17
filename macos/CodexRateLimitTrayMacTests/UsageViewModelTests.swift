import XCTest
@testable import CodexRateLimitTrayMac

@MainActor
final class UsageViewModelTests: XCTestCase {
    func testMissingAuthFileSetsAuthFileState() async {
        let viewModel = UsageViewModel(
            authReader: FakeAuthReader(result: .fileNotFound),
            usageClient: FakeUsageClient(state: Self.successState()),
            scheduler: RefreshScheduler(interval: 30, repeats: false)
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state.errorKind, .authFile)
        XCTAssertEqual(viewModel.state.errorMessage, ".codex/auth.json がありません")
    }

    func testSuccessfulAuthAndFetchUpdatesState() async {
        let expected = Self.successState(fiveHourUsed: 40, weekUsed: 6)
        let usageClient = FakeUsageClient(state: expected)
        let viewModel = UsageViewModel(
            authReader: FakeAuthReader(result: .success("abc")),
            usageClient: usageClient,
            scheduler: RefreshScheduler(interval: 30, repeats: false)
        )

        await viewModel.refresh()

        XCTAssertEqual(usageClient.receivedToken, "abc")
        XCTAssertEqual(viewModel.state, expected)
    }

    func testOverlappingRefreshesAreIgnored() async {
        let usageClient = SuspendedUsageClient()
        let viewModel = UsageViewModel(
            authReader: FakeAuthReader(result: .success("abc")),
            usageClient: usageClient,
            scheduler: RefreshScheduler(interval: 30, repeats: false)
        )

        async let first: Void = viewModel.refresh()
        await usageClient.waitUntilStarted()
        async let second: Void = viewModel.refresh()
        await Task.yield()

        XCTAssertEqual(await usageClient.callCount, 1)

        usageClient.resume(with: Self.successState())
        _ = await (first, second)
    }

    private static func successState(fiveHourUsed: Double = 40, weekUsed: Double = 6) -> UsageState {
        UsageState.success(
            fiveHour: UsageWindow(usedPercent: fiveHourUsed, resetAt: Date(timeIntervalSince1970: 1_715_781_600)),
            week: UsageWindow(usedPercent: weekUsed, resetAt: Date(timeIntervalSince1970: 1_716_094_800))
        )
    }
}

private struct FakeAuthReader: AuthReading {
    let result: AuthReadResult

    func readAccessToken() -> AuthReadResult {
        result
    }
}

private final class FakeUsageClient: WhamUsageFetching {
    let state: UsageState
    private(set) var receivedToken: String?

    init(state: UsageState) {
        self.state = state
    }

    func fetchUsage(accessToken: String) async -> UsageState {
        receivedToken = accessToken
        return state
    }
}

private actor SuspendedUsageClient: WhamUsageFetching {
    private var continuation: CheckedContinuation<UsageState, Never>?
    private var startedContinuation: CheckedContinuation<Void, Never>?
    private(set) var callCount = 0

    nonisolated func fetchUsage(accessToken: String) async -> UsageState {
        await withCheckedContinuation { continuation in
            Task {
                await self.start(continuation: continuation)
            }
        }
    }

    func waitUntilStarted() async {
        if callCount > 0 {
            return
        }
        await withCheckedContinuation { continuation in
            startedContinuation = continuation
        }
    }

    func resume(with state: UsageState) {
        continuation?.resume(returning: state)
        continuation = nil
    }

    private func start(continuation: CheckedContinuation<UsageState, Never>) {
        callCount += 1
        self.continuation = continuation
        startedContinuation?.resume()
        startedContinuation = nil
    }
}
