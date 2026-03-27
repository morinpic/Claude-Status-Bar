import Foundation

protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

actor StatusService {
    private let session: URLSessionProtocol
    private let baseURL = URL(string: "https://status.claude.com/api/v2/summary.json")!
    private let baseInterval: TimeInterval = 60
    private let maxInterval: TimeInterval = 300
    private let requestTimeout: TimeInterval = 10

    private var currentInterval: TimeInterval = 60
    private var pollingTask: Task<Void, Never>?

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) {
                return date
            }

            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: string) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(string)"
            )
        }
        return decoder
    }()

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    func fetchStatus() async throws -> StatusSummary {
        var request = URLRequest(url: baseURL)
        request.timeoutInterval = requestTimeout

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StatusServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw StatusServiceError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let summary = try decoder.decode(StatusSummary.self, from: data)
            currentInterval = baseInterval
            return summary
        } catch {
            throw StatusServiceError.decodingError(error)
        }
    }

    func startPolling(onUpdate: @escaping @Sendable (Result<StatusSummary, Error>) -> Void) {
        stopPolling()
        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    let summary = try await fetchStatus()
                    onUpdate(.success(summary))
                    currentInterval = baseInterval
                } catch {
                    onUpdate(.failure(error))
                    currentInterval = min(currentInterval * 2, maxInterval)
                }
                try? await Task.sleep(for: .seconds(currentInterval))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}

enum StatusServiceError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return String(localized: "Invalid response from server")
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
