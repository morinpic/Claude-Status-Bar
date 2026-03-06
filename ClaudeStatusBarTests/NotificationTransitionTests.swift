import XCTest
@testable import ClaudeStatusBar

// MARK: - Mock

final class MockNotificationService: NotificationServiceProtocol {
    var incidentCallCount = 0
    var recoveryCallCount = 0
    var lastImpact: StatusIndicator?
    var lastAffectedCount: Int?
    var lastIncidentName: String?

    func requestAuthorization() {}

    func sendIncidentNotification(incidentName: String, impact: StatusIndicator, affectedCount: Int) {
        incidentCallCount += 1
        lastIncidentName = incidentName
        lastImpact = impact
        lastAffectedCount = affectedCount
    }

    func sendRecoveryNotification() {
        recoveryCallCount += 1
    }
}

// MARK: - Tests

final class NotificationTransitionTests: XCTestCase {

    private var mockService: MockNotificationService!
    private var viewModel: StatusViewModel!
    private let defaultsKey = "notificationsEnabled"

    override func setUp() {
        super.setUp()
        mockService = MockNotificationService()
        viewModel = StatusViewModel(notificationService: mockService, autoStart: false)
        UserDefaults.standard.set(true, forKey: defaultsKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        super.tearDown()
    }

    // MARK: - severityLevel

    func testSeverityLevels() {
        XCTAssertEqual(StatusIndicator.none.severityLevel, 0)
        XCTAssertEqual(StatusIndicator.minor.severityLevel, 1)
        XCTAssertEqual(StatusIndicator.major.severityLevel, 2)
        XCTAssertEqual(StatusIndicator.critical.severityLevel, 3)
    }

    // MARK: - 悪化で通知が飛ぶ

    func testNoneToMinorSendsIncidentNotification() {
        transition(from: .none, to: .minor)
        XCTAssertEqual(mockService.incidentCallCount, 1)
        XCTAssertEqual(mockService.recoveryCallCount, 0)
        XCTAssertEqual(mockService.lastImpact, .minor)
    }

    func testNoneToMajorSendsIncidentNotification() {
        transition(from: .none, to: .major)
        XCTAssertEqual(mockService.incidentCallCount, 1)
        XCTAssertEqual(mockService.lastImpact, .major)
    }

    func testMinorToMajorSendsIncidentNotification() {
        transition(from: .minor, to: .major)
        XCTAssertEqual(mockService.incidentCallCount, 1)
        XCTAssertEqual(mockService.recoveryCallCount, 0)
        XCTAssertEqual(mockService.lastImpact, .major)
    }

    func testMajorToCriticalSendsIncidentNotification() {
        transition(from: .major, to: .critical)
        XCTAssertEqual(mockService.incidentCallCount, 1)
        XCTAssertEqual(mockService.lastImpact, .critical)
    }

    // MARK: - 復旧で通知が飛ぶ

    func testMajorToNoneSendsRecoveryNotification() {
        transition(from: .major, to: .none)
        XCTAssertEqual(mockService.incidentCallCount, 0)
        XCTAssertEqual(mockService.recoveryCallCount, 1)
    }

    func testMinorToNoneSendsRecoveryNotification() {
        transition(from: .minor, to: .none)
        XCTAssertEqual(mockService.recoveryCallCount, 1)
    }

    func testCriticalToNoneSendsRecoveryNotification() {
        transition(from: .critical, to: .none)
        XCTAssertEqual(mockService.recoveryCallCount, 1)
    }

    // MARK: - 通知が飛ばない

    func testSameLevelDoesNotNotify() {
        transition(from: .minor, to: .minor)
        XCTAssertEqual(mockService.incidentCallCount, 0)
        XCTAssertEqual(mockService.recoveryCallCount, 0)
    }

    func testPartialImprovementDoesNotNotify() {
        transition(from: .major, to: .minor)
        XCTAssertEqual(mockService.incidentCallCount, 0)
        XCTAssertEqual(mockService.recoveryCallCount, 0)
    }

    func testCriticalToMajorDoesNotNotify() {
        transition(from: .critical, to: .major)
        XCTAssertEqual(mockService.incidentCallCount, 0)
        XCTAssertEqual(mockService.recoveryCallCount, 0)
    }

    func testNoneToNoneDoesNotNotify() {
        transition(from: .none, to: .none)
        XCTAssertEqual(mockService.incidentCallCount, 0)
        XCTAssertEqual(mockService.recoveryCallCount, 0)
    }

    // MARK: - notificationsEnabled = false

    func testDisabledNotificationsDoNotSendOnWorsening() {
        UserDefaults.standard.set(false, forKey: defaultsKey)
        transition(from: .none, to: .major)
        XCTAssertEqual(mockService.incidentCallCount, 0)
    }

    func testDisabledNotificationsDoNotSendOnRecovery() {
        UserDefaults.standard.set(false, forKey: defaultsKey)
        transition(from: .major, to: .none)
        XCTAssertEqual(mockService.recoveryCallCount, 0)
    }

    // MARK: - 初回取得（previousStatus が nil）

    func testInitialFetchDoesNotNotify() async {
        // previousStatus is nil on init, so apply() skips checkStatusTransition
        let summary = makeIncidentSummary()
        await MainActor.run {
            viewModel.apply(summary)
        }
        XCTAssertEqual(mockService.incidentCallCount, 0)
        XCTAssertEqual(mockService.recoveryCallCount, 0)
    }

    // MARK: - 通知コンテンツ

    func testIncidentNotificationPassesAffectedCount() {
        viewModel.checkStatusTransition(from: .none, to: .major, incidents: [], affectedCount: 3)
        XCTAssertEqual(mockService.lastAffectedCount, 3)
    }

    func testIncidentNotificationPassesIncidentName() {
        let incident = makeIncident(name: "API Disruption", impact: .major)
        viewModel.checkStatusTransition(from: .none, to: .major, incidents: [incident], affectedCount: 1)
        XCTAssertEqual(mockService.lastIncidentName, "API Disruption")
    }

    func testIncidentNotificationUsesUnknownWhenNoIncidents() {
        viewModel.checkStatusTransition(from: .none, to: .minor, incidents: [], affectedCount: 0)
        XCTAssertEqual(mockService.lastIncidentName, "Unknown incident")
    }

    // MARK: - Helpers

    private func transition(from previous: StatusIndicator, to current: StatusIndicator) {
        viewModel.checkStatusTransition(from: previous, to: current, incidents: [], affectedCount: 0)
    }

    private func makeIncident(name: String, impact: StatusIndicator) -> Incident {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let json = """
        {
          "id": "inc001",
          "name": "\(name)",
          "status": "investigating",
          "impact": "\(impact.rawValue)",
          "created_at": "2026-03-06T00:00:00Z",
          "updated_at": "2026-03-06T00:00:00Z",
          "incident_updates": []
        }
        """
        return try! decoder.decode(Incident.self, from: Data(json.utf8))
    }

    private func makeIncidentSummary() -> StatusSummary {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(StatusSummary.self, from: Data(StatusModelsTests.incidentJSON.utf8))
    }
}
