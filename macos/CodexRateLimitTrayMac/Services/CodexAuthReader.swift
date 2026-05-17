import Foundation

protocol AuthReading {
    func readAccessToken() -> AuthReadResult
}

struct CodexAuthReader: AuthReading {
    private let authFileURL: URL
    private let fileManager: FileManager

    init(
        baseDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) {
        self.authFileURL = baseDirectory
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("auth.json")
        self.fileManager = fileManager
    }

    func readAccessToken() -> AuthReadResult {
        guard fileManager.fileExists(atPath: authFileURL.path) else {
            return .fileNotFound
        }

        let data: Data
        do {
            data = try Data(contentsOf: authFileURL)
        } catch {
            return .fileNotFound
        }

        do {
            let response = try JSONDecoder().decode(AuthFile.self, from: data)
            guard let token = response.tokens.accessToken, !token.isEmpty else {
                return .tokenMissing
            }
            return .success(token)
        } catch {
            return .invalidJSON
        }
    }
}

private struct AuthFile: Decodable {
    let tokens: Tokens
}

private struct Tokens: Decodable {
    let accessToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
