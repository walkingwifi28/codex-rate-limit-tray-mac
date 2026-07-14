import Foundation

enum UsageErrorKind: Error, Equatable {
    case none
    case authentication
    case network
    case server
    case invalidResponse
    case authFile
}

struct UsageWindow: Equatable {
    let usedPercent: Double
    let resetAt: Date

    var remainingPercent: Double {
        let clampedUsedPercent = max(0, min(100, usedPercent))
        return max(0, min(100, 100 - clampedUsedPercent))
    }
}

struct UsageState: Equatable {
    let week: UsageWindow
    let errorKind: UsageErrorKind
    let errorMessage: String?

    var hasError: Bool {
        errorKind != .none
    }

    static func success(week: UsageWindow) -> UsageState {
        UsageState(
            week: week,
            errorKind: .none,
            errorMessage: nil
        )
    }

    static func error(_ kind: UsageErrorKind, _ message: String) -> UsageState {
        let now = Date()
        let empty = UsageWindow(usedPercent: 0, resetAt: now)
        return UsageState(
            week: empty,
            errorKind: kind,
            errorMessage: message
        )
    }
}

enum AuthReadResult: Equatable {
    case success(String)
    case fileNotFound
    case invalidJSON
    case tokenMissing
}
