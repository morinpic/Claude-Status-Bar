import Foundation
import Observation
import SwiftUI

@Observable
final class StatusViewModel {
    var overallStatus: StatusIndicator = .none
    var components: [Component] = []
    var activeIncidents: [Incident] = []
    var lastUpdated: Date?
    var isLoading = false
    var error: Error?
    var selectedIconDesignRaw: String = UserDefaults.standard.string(forKey: "selectedIconDesign") ?? IconDesignType.default.rawValue

    private let service = StatusService()
    private let notificationService: NotificationServiceProtocol
    private var previousStatus: StatusIndicator?

    var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }

    init(notificationService: NotificationServiceProtocol = NotificationService.shared, autoStart: Bool = true) {
        self.notificationService = notificationService
        if autoStart {
            notificationService.requestAuthorization()
        }
        if autoStart {
            startMonitoring()
        }
    }

    var hasError: Bool { error != nil }

    var selectedIconDesign: IconDesignType {
        get { IconDesignType(rawValue: selectedIconDesignRaw) ?? .default }
        set {
            selectedIconDesignRaw = newValue.rawValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "selectedIconDesign")
        }
    }

    var currentIconState: IconState {
        IconState.from(overallStatus, hasError: hasError)
    }

    var menuBarIconAssetName: String? {
        let design = selectedIconDesign
        guard design != .default else { return nil }
        return design.assetName(for: currentIconState)
    }

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
    func apply(_ summary: StatusSummary) {
        let newStatus = summary.status.indicator
        let activeIncidentsList = summary.incidents
            .filter { $0.status != .resolved && $0.status != .postmortem }
        let affectedCount = summary.components
            .filter { !$0.group && $0.status != .operational }
            .count

        if let previous = previousStatus {
            checkStatusTransition(from: previous, to: newStatus, incidents: activeIncidentsList, affectedCount: affectedCount)
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

    func checkStatusTransition(
        from previous: StatusIndicator,
        to current: StatusIndicator,
        incidents: [Incident],
        affectedCount: Int
    ) {
        guard notificationsEnabled else { return }

        if previous.severityLevel < current.severityLevel {
            let incidentName = incidents.first?.name ?? "Unknown incident"
            notificationService.sendIncidentNotification(incidentName: incidentName, impact: current, affectedCount: affectedCount)
        } else if previous != .none && current == .none {
            notificationService.sendRecoveryNotification()
        }
    }
}
