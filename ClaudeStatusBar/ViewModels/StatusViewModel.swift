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
    private let notificationService = NotificationService.shared
    private var previousStatus: StatusIndicator?

    init() {
        notificationService.requestAuthorization()
        startMonitoring()
    }

    var hasError: Bool { error != nil }

    var menuBarIcon: String {
        if hasError { return "exclamationmark.circle.fill" }
        return "circle.fill"
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
        let newStatus = summary.status.indicator
        let activeIncidentsList = summary.incidents
            .filter { $0.status != .resolved && $0.status != .postmortem }

        if let previous = previousStatus {
            checkStatusTransition(from: previous, to: newStatus, incidents: activeIncidentsList)
        }

        previousStatus = newStatus
        overallStatus = newStatus
        components = summary.components
            .filter { !$0.group }
            .sorted { $0.position < $1.position }
        activeIncidents = activeIncidentsList
        lastUpdated = Date()
        isLoading = false
        error = nil
    }

    private func checkStatusTransition(
        from previous: StatusIndicator,
        to current: StatusIndicator,
        incidents: [Incident]
    ) {
        if previous == .none && current != .none {
            let incidentName = incidents.first?.name ?? "Unknown incident"
            notificationService.sendIncidentNotification(incidentName: incidentName)
        } else if previous != .none && current == .none {
            notificationService.sendRecoveryNotification()
        }
    }
}
