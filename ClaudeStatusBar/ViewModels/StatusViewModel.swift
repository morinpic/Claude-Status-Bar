import Foundation
import Observation

@Observable
final class StatusViewModel {
    var overallStatus: StatusIndicator = .none
    var components: [Component] = []
    var activeIncidents: [Incident] = []
    var lastUpdated: Date?
    var isLoading = false
    var error: Error?

    private let service = StatusService()

    init() {
        startMonitoring()
    }

    var menuBarIcon: String {
        switch overallStatus {
        case .none: return "circle.fill"
        case .minor: return "circle.fill"
        case .major: return "circle.fill"
        case .critical: return "circle.fill"
        }
    }

    var menuBarIconColor: String {
        switch overallStatus {
        case .none: return "green"
        case .minor: return "yellow"
        case .major: return "orange"
        case .critical: return "red"
        }
    }

    var overallStatusText: String {
        switch overallStatus {
        case .none: return "All Systems Operational"
        case .minor: return "Minor Issues"
        case .major: return "Major Outage"
        case .critical: return "Critical Outage"
        }
    }

    func startMonitoring() {
        Task {
            isLoading = true
            await service.startPolling { [weak self] result in
                Task { @MainActor in
                    self?.handleResult(result)
                }
            }
        }
    }

    func stopMonitoring() {
        Task {
            await service.stopPolling()
        }
    }

    func refresh() {
        Task {
            isLoading = true
            do {
                let summary = try await service.fetchStatus()
                await MainActor.run {
                    apply(summary)
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }

    @MainActor
    private func handleResult(_ result: Result<StatusSummary, Error>) {
        switch result {
        case .success(let summary):
            apply(summary)
        case .failure(let error):
            self.error = error
            self.isLoading = false
        }
    }

    @MainActor
    private func apply(_ summary: StatusSummary) {
        overallStatus = summary.status.indicator
        components = summary.components
            .filter { !$0.group }
            .sorted { $0.position < $1.position }
        activeIncidents = summary.incidents
            .filter { $0.status != .resolved && $0.status != .postmortem }
        lastUpdated = Date()
        isLoading = false
        error = nil
    }
}
