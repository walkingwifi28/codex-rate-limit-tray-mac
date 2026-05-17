import Foundation

@MainActor
final class RefreshScheduler {
    nonisolated static let defaultInterval: TimeInterval = 30

    let interval: TimeInterval
    private let repeats: Bool
    private var timer: Timer?

    init(interval: TimeInterval = RefreshScheduler.defaultInterval, repeats: Bool = true) {
        self.interval = interval
        self.repeats = repeats
    }

    func start(_ action: @escaping @MainActor () async -> Void) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats) { _ in
            Task { @MainActor in
                await action()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        timer?.invalidate()
    }
}
