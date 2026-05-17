import XCTest
@testable import CodexRateLimitTrayMac

final class CodexAuthReaderTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testReadsTokensAccessToken() throws {
        try writeAuthJSON(#"{"tokens":{"access_token":"abc"}}"#)
        let reader = CodexAuthReader(baseDirectory: temporaryDirectory)

        XCTAssertEqual(reader.readAccessToken(), .success("abc"))
    }

    func testMissingFileReturnsFileNotFound() {
        let reader = CodexAuthReader(baseDirectory: temporaryDirectory)

        XCTAssertEqual(reader.readAccessToken(), .fileNotFound)
    }

    func testInvalidJSONReturnsInvalidJSON() throws {
        try writeAuthJSON("{")
        let reader = CodexAuthReader(baseDirectory: temporaryDirectory)

        XCTAssertEqual(reader.readAccessToken(), .invalidJSON)
    }

    func testMissingTokenReturnsTokenMissing() throws {
        try writeAuthJSON(#"{"tokens":{}}"#)
        let reader = CodexAuthReader(baseDirectory: temporaryDirectory)

        XCTAssertEqual(reader.readAccessToken(), .tokenMissing)
    }

    func testMissingTokensObjectReturnsTokenMissing() throws {
        try writeAuthJSON(#"{}"#)
        let reader = CodexAuthReader(baseDirectory: temporaryDirectory)

        XCTAssertEqual(reader.readAccessToken(), .tokenMissing)
    }

    private func writeAuthJSON(_ json: String) throws {
        let codexDirectory = temporaryDirectory.appendingPathComponent(".codex", isDirectory: true)
        try FileManager.default.createDirectory(at: codexDirectory, withIntermediateDirectories: true)
        try json.write(to: codexDirectory.appendingPathComponent("auth.json"), atomically: true, encoding: .utf8)
    }
}
