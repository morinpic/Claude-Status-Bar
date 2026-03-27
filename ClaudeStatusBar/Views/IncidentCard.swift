import SwiftUI

struct IncidentCard: View {
    let incident: Incident

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(incident.name)
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

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(
                "Updated: \(incident.updatedAt.formatted(date: .abbreviated, time: .shortened))",
                comment: "Label showing when the incident was last updated"
            )
            .font(.caption2)
            .foregroundStyle(.tertiary)

            if let latestUpdate = incident.incidentUpdates.first {
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

    private var impactColor: Color {
        switch incident.impact {
        case .none: return .green
        case .minor: return .yellow
        case .major: return .orange
        case .critical: return .red
        }
    }

    private var impactText: String {
        switch incident.impact {
        case .none: return String(localized: "None")
        case .minor: return String(localized: "Minor")
        case .major: return String(localized: "Major")
        case .critical: return String(localized: "Critical")
        }
    }

    private var statusText: String {
        switch incident.status {
        case .investigating: return String(localized: "Investigating")
        case .identified: return String(localized: "Identified")
        case .monitoring: return String(localized: "Monitoring")
        case .resolved: return String(localized: "Resolved")
        case .postmortem: return String(localized: "Postmortem")
        }
    }
}
