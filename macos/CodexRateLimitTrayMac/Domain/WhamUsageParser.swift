import Foundation

struct WhamUsageParser {
    func parse(_ data: Data) -> Result<UsageState, UsageErrorKind> {
        do {
            let response = try JSONDecoder().decode(UsageResponse.self, from: data)
            return .success(
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
            )
        } catch {
            return .failure(.invalidResponse)
        }
    }
}

private struct UsageResponse: Decodable {
    let rateLimit: RateLimit

    enum CodingKeys: String, CodingKey {
        case rateLimit = "rate_limit"
    }
}

private struct RateLimit: Decodable {
    let primaryWindow: RateLimitWindow
    let secondaryWindow: RateLimitWindow

    enum CodingKeys: String, CodingKey {
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

private struct RateLimitWindow: Decodable {
    let usedPercent: Double
    let resetAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case resetAt = "reset_at"
    }
}
