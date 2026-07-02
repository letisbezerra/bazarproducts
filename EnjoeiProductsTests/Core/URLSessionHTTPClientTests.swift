import XCTest
@testable import EnjoeiProducts

final class URLSessionHTTPClientTests: XCTestCase {
    private struct DummyPayload: Decodable, Equatable {
        let value: String
    }

    override func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    func test_send_decodesOnSuccess() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Data(#"{"value":"hello"}"#.utf8), statusCode: 200)

        let result: DummyPayload = try await sut.send(Endpoint(path: "/thing"))

        XCTAssertEqual(result, DummyPayload(value: "hello"))
    }

    func test_send_throwsDecodingErrorOnMalformedJSON() async {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Data("not json".utf8), statusCode: 200)

        await assertThrows(.decoding) {
            let _: DummyPayload = try await sut.send(Endpoint(path: "/thing"))
        }
    }

    func test_send_throwsHTTPErrorOnNon2xxStatus() async {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Data(), statusCode: 404)

        await assertThrows(.http(status: 404)) {
            let _: DummyPayload = try await sut.send(Endpoint(path: "/thing"))
        }
    }

    func test_send_throwsTransportErrorOnRequestFailure() async {
        let sut = makeSUT()
        URLProtocolStub.stub(error: URLError(.notConnectedToInternet))

        await assertThrows(.transport) {
            let _: DummyPayload = try await sut.send(Endpoint(path: "/thing"))
        }
    }

    func test_send_encodesQueryItemsInRequestURL() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Data(#"{"value":"x"}"#.utf8), statusCode: 200)

        let _: DummyPayload = try await sut.send(
            Endpoint(path: "/thing", queryItems: [URLQueryItem(name: "page", value: "2")])
        )

        XCTAssertEqual(URLProtocolStub.lastRequest?.url?.query, "page=2")
    }

    private func makeSUT() -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        return URLSessionHTTPClient(baseURL: URL(string: "https://example.com/api")!, session: session)
    }

    private func assertThrows(
        _ expected: NetworkError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected) but no error was thrown", file: file, line: line)
        } catch let error as NetworkError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Expected \(expected) but got \(error)", file: file, line: line)
        }
    }
}
