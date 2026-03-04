import XCTest
@testable import ClaudeStatusBar

// MARK: - Mock URLSession

final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var requestedURLs: [URL] = []

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let url = request.url {
            requestedURLs.append(url)
        }
        if let error = mockError {
            throw error
        }
        guard let data = mockData, let response = mockResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, response)
    }

    func configure(
        statusCode: Int = 200,
        json: String = StatusModelsTests.allOperationalJSON
    ) {
        mockData = Data(json.utf8)
        mockResponse = HTTPURLResponse(
            url: URL(string: "https://status.claude.com/api/v2/summary.json")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
    }
}

// MARK: - Tests

final class StatusServiceTests: XCTestCase {

    private var mockSession: MockURLSession!
    private var service: StatusService!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        service = StatusService(session: mockSession)
    }

    // MARK: - fetchStatus

    func testFetchStatusSuccess() async throws {
        mockSession.configure(json: StatusModelsTests.allOperationalJSON)

        let summary = try await service.fetchStatus()

        XCTAssertEqual(summary.status.indicator, .none)
        XCTAssertEqual(summary.components.count, 3)
        XCTAssertTrue(summary.incidents.isEmpty)
    }

    func testFetchStatusWithIncident() async throws {
        mockSession.configure(json: StatusModelsTests.incidentJSON)

        let summary = try await service.fetchStatus()

        XCTAssertEqual(summary.status.indicator, .major)
        XCTAssertEqual(summary.incidents.count, 1)
        XCTAssertEqual(summary.incidents[0].name, "Elevated errors on Claude API")
    }

    func testFetchStatusHTTPError() async {
        mockSession.configure(statusCode: 500)

        do {
            _ = try await service.fetchStatus()
            XCTFail("Expected httpError to be thrown")
        } catch let error as StatusServiceError {
            if case .httpError(let code) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchStatusNetworkError() async {
        mockSession.mockError = URLError(.notConnectedToInternet)

        do {
            _ = try await service.fetchStatus()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    func testFetchStatusDecodingError() async {
        mockSession.configure()
        mockSession.mockData = Data("invalid json".utf8)

        do {
            _ = try await service.fetchStatus()
            XCTFail("Expected decodingError to be thrown")
        } catch let error as StatusServiceError {
            if case .decodingError = error {
                // expected
            } else {
                XCTFail("Expected decodingError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchStatusInvalidResponse() async {
        mockSession.mockData = Data("{}".utf8)
        mockSession.mockResponse = URLResponse(
            url: URL(string: "https://status.claude.com")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )

        do {
            _ = try await service.fetchStatus()
            XCTFail("Expected invalidResponse to be thrown")
        } catch let error as StatusServiceError {
            if case .invalidResponse = error {
                // expected
            } else {
                XCTFail("Expected invalidResponse, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchStatusRequestsCorrectURL() async throws {
        mockSession.configure()

        _ = try await service.fetchStatus()

        XCTAssertEqual(mockSession.requestedURLs.count, 1)
        XCTAssertEqual(
            mockSession.requestedURLs[0].absoluteString,
            "https://status.claude.com/api/v2/summary.json"
        )
    }

    // MARK: - Polling

    func testPollingCallsBackOnSuccess() async throws {
        mockSession.configure()

        let expectation = XCTestExpectation(description: "Polling callback")
        await service.startPolling { result in
            if case .success(let summary) = result {
                XCTAssertEqual(summary.status.indicator, .none)
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 5)
        await service.stopPolling()
    }

    func testPollingCallsBackOnFailure() async {
        mockSession.mockError = URLError(.timedOut)

        let expectation = XCTestExpectation(description: "Polling error callback")
        await service.startPolling { result in
            if case .failure = result {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 5)
        await service.stopPolling()
    }
}
