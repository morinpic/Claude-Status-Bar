#if DEBUG
import Foundation

enum DebugStatusPreset: String, CaseIterable {
    case live = "Live (API)"
    case operational = "All Operational"
    case minor = "Minor Issues"
    case major = "Major Outage"
    case critical = "Critical Outage"
}

enum DebugIncidentPreset: String, CaseIterable {
    case none = "No Incidents"
    case singleMinor = "1 Incident (minor)"
    case singleMajor = "1 Incident (major)"
    case multiple = "Multiple Incidents"
}

enum DebugComponentPreset: String, CaseIterable {
    case allOperational = "All Operational"
    case someDegraded = "Some Degraded"
    case partialOutage = "Partial Outage"
    case majorOutage = "Major Outage"
    case mixed = "Mixed States"
}

enum DebugErrorPreset: String, CaseIterable {
    case none = "No Error"
    case networkError = "Network Error"
    case httpError = "HTTP Error (500)"
}

struct DebugDataFactory {

    static func makeComponents(preset: DebugComponentPreset) -> [Component] {
        let names = ["claude.ai", "Claude API", "Claude Code", "platform.claude.com", "Claude for Government"]
        let statuses: [ComponentStatus]

        switch preset {
        case .allOperational:
            statuses = Array(repeating: .operational, count: names.count)
        case .someDegraded:
            statuses = [.operational, .degradedPerformance, .operational, .degradedPerformance, .operational]
        case .partialOutage:
            statuses = [.operational, .partialOutage, .operational, .operational, .operational]
        case .majorOutage:
            statuses = [.majorOutage, .majorOutage, .operational, .operational, .operational]
        case .mixed:
            statuses = [.operational, .degradedPerformance, .partialOutage, .majorOutage, .operational]
        }

        return names.enumerated().map { index, name in
            Component(
                id: "debug-\(index)",
                name: name,
                status: statuses[index],
                createdAt: Date(),
                updatedAt: Date(),
                position: index,
                description: nil,
                showcase: true,
                startDate: nil,
                groupId: nil,
                pageId: "debug-page",
                group: false,
                onlyShowIfDegraded: false
            )
        }
    }

    static func makeIncidents(preset: DebugIncidentPreset) -> [Incident] {
        switch preset {
        case .none:
            return []
        case .singleMinor:
            return [makeIncident(name: "Elevated error rates on Claude API", impact: .minor, status: .investigating)]
        case .singleMajor:
            return [makeIncident(name: "Claude.ai is experiencing downtime", impact: .major, status: .identified)]
        case .multiple:
            return [
                makeIncident(name: "Claude.ai is experiencing downtime", impact: .major, status: .identified),
                makeIncident(name: "Elevated error rates on Claude API", impact: .minor, status: .monitoring)
            ]
        }
    }

    static func makeIncident(name: String, impact: StatusIndicator, status: IncidentStatus) -> Incident {
        let update = IncidentUpdate(
            id: UUID().uuidString,
            status: status,
            body: "We are currently investigating this issue. Updates will be provided as available.",
            createdAt: Date().addingTimeInterval(-300),
            affectedComponents: nil
        )
        return Incident(
            id: UUID().uuidString,
            name: name,
            status: status,
            impact: impact,
            createdAt: Date().addingTimeInterval(-600),
            updatedAt: Date().addingTimeInterval(-300),
            incidentUpdates: [update]
        )
    }

    static func makeError(preset: DebugErrorPreset) -> Error? {
        switch preset {
        case .none:
            return nil
        case .networkError:
            return URLError(.notConnectedToInternet)
        case .httpError:
            return StatusServiceError.httpError(statusCode: 500)
        }
    }
}
#endif
