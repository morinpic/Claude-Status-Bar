import SwiftUI

struct ComponentRow: View {
    let component: Component

    var body: some View {
        HStack {
            Text(component.name)
                .lineLimit(1)
            Spacer()
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var statusColor: Color {
        switch component.status {
        case .operational:
            return .green
        case .degradedPerformance:
            return .yellow
        case .partialOutage:
            return .orange
        case .majorOutage:
            return .red
        }
    }

    private var statusText: String {
        switch component.status {
        case .operational:
            return "Operational"
        case .degradedPerformance:
            return "Degraded"
        case .partialOutage:
            return "Partial Outage"
        case .majorOutage:
            return "Major Outage"
        }
    }
}
