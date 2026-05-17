import Foundation

protocol WhamUsageFetching {
    func fetchUsage(accessToken: String) async -> UsageState
}

struct WhamUsageClient: WhamUsageFetching {
    static let endpoint = URL(string: "https://chatgpt.com/backend-api/wham/usage")!

    private let session: URLSession
    private let parser: WhamUsageParser

    init(session: URLSession = .shared, parser: WhamUsageParser = WhamUsageParser()) {
        self.session = session
        self.parser = parser
    }

    func fetchUsage(accessToken: String) async -> UsageState {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .error(.network, "ネットワークエラー")
            }

            switch httpResponse.statusCode {
            case 200...299:
                switch parser.parse(data) {
                case let .success(state):
                    return state
                case .failure:
                    return .error(.invalidResponse, "レスポンスが不正です")
                }
            case 401, 403:
                return .error(.authentication, "認証できません")
            case 500...599:
                return .error(.server, "サーバーエラー")
            default:
                return .error(.invalidResponse, "レスポンスが不正です")
            }
        } catch {
            return .error(.network, "ネットワークエラー")
        }
    }
}
