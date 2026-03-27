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
    private let notificationService = NotificationService.shared
    private let notificationSettings = NotificationSettingsService.shared
    private var previousStatus: StatusIndicator?
    private var previousComponentStatuses: [String: ComponentStatus] = [:]

    init() {
        notificationService.requestAuthorization()
        startMonitoring()
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
        let apiStatus = summary.status.indicator
        let activeIncidentsList = summary.incidents
            .filter { $0.status != .resolved && $0.status != .postmortem }

        let maxIncidentImpact = activeIncidentsList
            .map { $0.impact }
            .max()

        let effectiveStatus = [apiStatus, maxIncidentImpact]
            .compactMap { $0 }
            .max() ?? .none

        if let previous = previousStatus {
            checkStatusTransition(from: previous, to: effectiveStatus, incidents: activeIncidentsList)
        }

        previousStatus = effectiveStatus
        overallStatus = effectiveStatus

        let filteredComponents = summary.components
            .filter { !$0.group }
            .sorted { $0.position < $1.position }
        notificationSettings.initializeIfNeeded(allComponentIDs: filteredComponents.map { $0.id })
        checkComponentTransitions(newComponents: filteredComponents)
        previousComponentStatuses = Dictionary(
            uniqueKeysWithValues: filteredComponents.map { ($0.id, $0.status) }
        )
        components = filteredComponents

        activeIncidents = activeIncidentsList
        lastUpdated = Date()
        isLoading = false
        error = nil
    }

    private func checkComponentTransitions(newComponents: [Component]) {
        guard !previousComponentStatuses.isEmpty else { return }

        for component in newComponents {
            guard notificationSettings.isNotificationEnabled(for: component.id) else { continue }

            let previousStatus = previousComponentStatuses[component.id]

            if previousStatus == .operational && component.status != .operational {
                notificationService.sendComponentIncidentNotification(
                    componentName: component.name,
                    status: component.status
                )
            } else if previousStatus != nil && previousStatus != .operational && component.status == .operational {
                notificationService.sendComponentRecoveryNotification(componentName: component.name)
            }
        }
    }

    func isComponentNotificationEnabled(_ componentID: String) -> Bool {
        notificationSettings.isNotificationEnabled(for: componentID)
    }

    func toggleComponentNotification(_ componentID: String, enabled: Bool) {
        notificationSettings.setNotificationEnabled(enabled, for: componentID, allComponentIDs: components.map { $0.id })
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

    #if DEBUG
    var isDebugMode = false

    func applyDebugState(
        statusPreset: DebugStatusPreset,
        incidentPreset: DebugIncidentPreset,
        componentPreset: DebugComponentPreset,
        errorPreset: DebugErrorPreset,
        isLoadingOverride: Bool
    ) {
        if statusPreset == .live {
            exitDebugMode()
            return
        }

        isDebugMode = true
        stopMonitoring()

        let statusIndicator: StatusIndicator
        switch statusPreset {
        case .live: return // handled above
        case .operational: statusIndicator = .none
        case .minor: statusIndicator = .minor
        case .major: statusIndicator = .major
        case .critical: statusIndicator = .critical
        }

        let incidents = DebugDataFactory.makeIncidents(preset: incidentPreset)
        let maxIncidentImpact = incidents.map { $0.impact }.max()
        let effectiveStatus = [statusIndicator, maxIncidentImpact]
            .compactMap { $0 }
            .max() ?? .none

        overallStatus = effectiveStatus
        activeIncidents = incidents
        components = DebugDataFactory.makeComponents(preset: componentPreset)
        error = DebugDataFactory.makeError(preset: errorPreset)
        isLoading = isLoadingOverride
        lastUpdated = Date()
    }

    func exitDebugMode() {
        isDebugMode = false
        error = nil
        isLoading = false
        startMonitoring()
    }

    func debugSendIncidentNotification() {
        notificationService.sendIncidentNotification(incidentName: "[Debug] Test incident on Claude API")
    }

    func debugSendRecoveryNotification() {
        notificationService.sendRecoveryNotification()
    }

    func debugSimulateComponentTransition(
        componentName: String,
        from oldStatus: ComponentStatus,
        to newStatus: ComponentStatus
    ) {
        guard let index = components.firstIndex(where: { $0.name == componentName }) else { return }
        let component = components[index]

        previousComponentStatuses[component.id] = oldStatus

        let updatedComponent = Component(
            id: component.id,
            name: component.name,
            status: newStatus,
            createdAt: component.createdAt,
            updatedAt: Date(),
            position: component.position,
            description: component.description,
            showcase: component.showcase,
            startDate: component.startDate,
            groupId: component.groupId,
            pageId: component.pageId,
            group: component.group,
            onlyShowIfDegraded: component.onlyShowIfDegraded
        )

        checkComponentTransitions(newComponents: [updatedComponent])

        components[index] = updatedComponent
        lastUpdated = Date()
    }

    func debugSimulateTransition(from: StatusIndicator, to: StatusIndicator) {
        previousStatus = from

        let incidents: [Incident]
        if to != .none {
            incidents = [DebugDataFactory.makeIncident(
                name: "[Debug] Simulated \(to.rawValue) incident",
                impact: to,
                status: .investigating
            )]
        } else {
            incidents = []
        }

        checkStatusTransition(from: from, to: to, incidents: incidents)

        overallStatus = to
        activeIncidents = incidents
        lastUpdated = Date()
    }
    #endif
}
