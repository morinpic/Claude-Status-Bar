import XCTest
@testable import ClaudeStatusBar

@MainActor
final class StatusViewModelTests: XCTestCase {

    private func makeSummary(
        indicator: StatusIndicator,
        incidents: [Incident] = []
    ) -> StatusSummary {
        StatusSummary(
            page: Page(
                id: "test",
                name: "Claude",
                url: "https://status.claude.com",
                timeZone: "Etc/UTC",
                updatedAt: Date()
            ),
            components: [],
            incidents: incidents,
            scheduledMaintenances: [],
            status: Status(indicator: indicator, description: "")
        )
    }

    private func makeIncident(
        impact: StatusIndicator,
        status: IncidentStatus = .investigating
    ) -> Incident {
        Incident(
            id: UUID().uuidString,
            name: "Test incident",
            status: status,
            impact: impact,
            createdAt: Date(),
            updatedAt: Date(),
            incidentUpdates: []
        )
    }

    // MARK: - overallStatus tests

    func testApiNoneWithActiveMinorIncident_overallStatusIsMinor() {
        let vm = StatusViewModel()
        let summary = makeSummary(
            indicator: .none,
            incidents: [makeIncident(impact: .minor)]
        )
        vm.apply(summary)
        XCTAssertEqual(vm.overallStatus, .minor)
    }

    func testApiMajorWithActiveCriticalIncident_overallStatusIsCritical() {
        let vm = StatusViewModel()
        let summary = makeSummary(
            indicator: .major,
            incidents: [makeIncident(impact: .critical)]
        )
        vm.apply(summary)
        XCTAssertEqual(vm.overallStatus, .critical)
    }

    func testApiNoneWithNoIncidents_overallStatusIsNone() {
        let vm = StatusViewModel()
        let summary = makeSummary(indicator: .none)
        vm.apply(summary)
        XCTAssertEqual(vm.overallStatus, .none)
    }

    func testApiMinorWithNoIncidents_overallStatusIsMinor() {
        let vm = StatusViewModel()
        let summary = makeSummary(indicator: .minor)
        vm.apply(summary)
        XCTAssertEqual(vm.overallStatus, .minor)
    }

    func testResolvedIncidentsAreIgnored() {
        let vm = StatusViewModel()
        let summary = makeSummary(
            indicator: .none,
            incidents: [makeIncident(impact: .critical, status: .resolved)]
        )
        vm.apply(summary)
        XCTAssertEqual(vm.overallStatus, .none)
    }

    // MARK: - StatusIndicator Comparable

    func testStatusIndicatorOrdering() {
        XCTAssertTrue(StatusIndicator.none < .minor)
        XCTAssertTrue(StatusIndicator.minor < .major)
        XCTAssertTrue(StatusIndicator.major < .critical)
        XCTAssertFalse(StatusIndicator.critical < .none)
    }
}
