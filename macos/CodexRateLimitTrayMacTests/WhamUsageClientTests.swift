import XCTest
@testable import CodexRateLimitTrayMac

final class WhamUsageClientTests: XCTestCase {
    override func tearDown() {
        TestURLProtocol.reset()
        super.tearDown()
    }

    func testSendsExpectedURLAndBearerToken() async throws {
        TestURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://chatgpt.com/backend-api/wham/usage")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer abc")
            return Self.usageResponse(statusCode: 200)
        }

        let state = await makeClient().fetchUsage(accessToken: "abc")

        XCTAssertFalse(state.hasError)
        XCTAssertEqual(state.week.usedPercent, 25.5)
    }

    func testUnauthorizedMapsToAuthentication() async {
        TestURLProtocol.handler = { _ in Self.emptyResponse(statusCode: 401) }

        let state = await makeClient().fetchUsage(accessToken: "abc")

        XCTAssertEqual(state.errorKind, .authentication)
        XCTAssertEqual(state.errorMessage, "認証できません")
    }

    func testForbiddenMapsToAuthentication() async {
        TestURLProtocol.handler = { _ in Self.emptyResponse(statusCode: 403) }

        let state = await makeClient().fetchUsage(accessToken: "abc")

        XCTAssertEqual(state.errorKind, .authentication)
    }

    func testServerErrorMapsToServer() async {
        TestURLProtocol.handler = { _ in Self.emptyResponse(statusCode: 503) }

        let state = await makeClient().fetchUsage(accessToken: "abc")

        XCTAssertEqual(state.errorKind, .server)
        XCTAssertEqual(state.errorMessage, "サーバーエラー")
    }

    func testTransportErrorMapsToNetwork() async {
        TestURLProtocol.handler = { _ in throw URLError(.timedOut) }

        let state = await makeClient().fetchUsage(accessToken: "abc")

        XCTAssertEqual(state.errorKind, .network)
        XCTAssertEqual(state.errorMessage, "ネットワークエラー")
    }

    func testInvalidUsageResponseMapsToInvalidResponse() async {
        TestURLProtocol.handler = { _ in
            (HTTPURLResponse(url: WhamUsageClient.endpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("{".utf8))
        }

        let state = await makeClient().fetchUsage(accessToken: "abc")

        XCTAssertEqual(state.errorKind, .invalidResponse)
        XCTAssertEqual(state.errorMessage, "レスポンスが不正です")
    }

    private func makeClient() -> WhamUsageClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TestURLProtocol.self]
        return WhamUsageClient(session: URLSession(configuration: configuration))
    }

    private static func usageResponse(statusCode: Int) -> (HTTPURLResponse, Data) {
        let data = Data("""
        {
          "rate_limit": {
            "primary_window": { "used_percent": 25.5, "reset_at": 1715781600 },
            "secondary_window": null
          }
        }
        """.utf8)
        return (HTTPURLResponse(url: WhamUsageClient.endpoint, statusCode: statusCode, httpVersion: nil, headerFields: nil)!, data)
    }

    private static func emptyResponse(statusCode: Int) -> (HTTPURLResponse, Data) {
        (HTTPURLResponse(url: WhamUsageClient.endpoint, statusCode: statusCode, httpVersion: nil, headerFields: nil)!, Data())
    }
}

private final class TestURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    static func reset() {
        handler = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
