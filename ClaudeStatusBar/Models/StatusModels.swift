import Foundation

// MARK: - API Response

struct StatusSummary: Codable, Sendable {
    let page: Page
    let components: [Component]
    let incidents: [Incident]
    let scheduledMaintenances: [Incident]
    let status: Status
}

// MARK: - Page

struct Page: Codable, Sendable {
    let id: String
    let name: String
    let url: String
    let timeZone: String
    let updatedAt: Date
}

// MARK: - Status

struct Status: Codable, Sendable {
    let indicator: StatusIndicator
    let description: String
}

enum StatusIndicator: String, Codable, Sendable, Comparable {
    case none
    case minor
    case major
    case critical

    var severity: Int {
        switch self {
        case .none: return 0
        case .minor: return 1
        case .major: return 2
        case .critical: return 3
        }
    }

    static func < (lhs: StatusIndicator, rhs: StatusIndicator) -> Bool {
        lhs.severity < rhs.severity
    }
}

// MARK: - Component

struct Component: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let status: ComponentStatus
    let createdAt: Date
    let updatedAt: Date
    let position: Int
    let description: String?
    let showcase: Bool
    let startDate: String?
    let groupId: String?
    let pageId: String
    let group: Bool
    let onlyShowIfDegraded: Bool
}

enum ComponentStatus: String, Codable, Sendable {
    case operational
    case degradedPerformance = "degraded_performance"
    case partialOutage = "partial_outage"
    case majorOutage = "major_outage"
}

// MARK: - Incident

struct Incident: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let status: IncidentStatus
    let impact: StatusIndicator
    let createdAt: Date
    let updatedAt: Date
    let incidentUpdates: [IncidentUpdate]
}

enum IncidentStatus: String, Codable, Sendable {
    case investigating
    case identified
    case monitoring
    case resolved
    case postmortem
}

// MARK: - Incident Update

struct IncidentUpdate: Codable, Sendable, Identifiable {
    let id: String
    let status: IncidentStatus
    let body: String
    let createdAt: Date
    let affectedComponents: [AffectedComponent]?
}

struct AffectedComponent: Codable, Sendable {
    let code: String
    let name: String
    let oldStatus: ComponentStatus
    let newStatus: ComponentStatus
}
