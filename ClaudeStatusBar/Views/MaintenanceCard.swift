import SwiftUI

struct MaintenanceCard: View {
    let maintenance: Incident
    var locale: Locale = .current

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(maintenance.name)
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 12) {
                Label {
                    Text(impactText)
                        .font(.caption)
                } icon: {
                    Circle()
                        .fill(impactColor)
                        .frame(width: 6, height: 6)
                }

                Label {
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(
                "Updated: \(maintenance.updatedAt.formatted(.dateTime.year().month().day().hour().minute().locale(locale)))",
                comment: "Label showing when the incident was last updated"
            )
            .font(.caption2)
            .foregroundStyle(.tertiary)

            if let latestUpdate = maintenance.incidentUpdates.first {
                Text(latestUpdate.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 8))
    }

    // MARK: - Private

    private var impactColor: Color {
        switch maintenance.impact {
        case .none: return Color(nsColor: .systemGreen)
        case .minor: return Color(nsColor: .systemYellow)
        case .major: return Color(nsColor: .systemOrange)
        case .critical: return Color(nsColor: .systemRed)
        }
    }

    private var impactText: String {
        switch maintenance.impact {
        case .none: return "None"
        case .minor: return "Minor"
        case .major: return "Major"
        case .critical: return "Critical"
        }
    }

    private var statusText: String {
        switch maintenance.status {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .verifying: return "Verifying"
        case .completed: return "Completed"
        case .investigating, .identified, .monitoring, .resolved, .postmortem:
            return maintenance.status.rawValue.capitalized
        }
    }
}

#Preview("Scheduled") {
    MaintenanceCard(maintenance: Incident(
        id: "maint-1",
        name: "Scheduled maintenance for Claude API",
        status: .scheduled,
        impact: .none,
        createdAt: Date().addingTimeInterval(-3600),
        updatedAt: Date().addingTimeInterval(-600),
        incidentUpdates: [
            IncidentUpdate(
                id: "upd-1",
                status: .scheduled,
                body: "We will be performing scheduled maintenance on the Claude API.",
                createdAt: Date().addingTimeInterval(-600),
                affectedComponents: nil
            )
        ]
    ))
    .padding()
    .frame(width: 300)
}

#Preview("In Progress") {
    MaintenanceCard(maintenance: Incident(
        id: "maint-2",
        name: "Database migration in progress",
        status: .inProgress,
        impact: .minor,
        createdAt: Date().addingTimeInterval(-7200),
        updatedAt: Date().addingTimeInterval(-300),
        incidentUpdates: [
            IncidentUpdate(
                id: "upd-2",
                status: .inProgress,
                body: "Maintenance is currently in progress. Some users may experience brief interruptions.",
                createdAt: Date().addingTimeInterval(-300),
                affectedComponents: nil
            )
        ]
    ))
    .padding()
    .frame(width: 300)
}
