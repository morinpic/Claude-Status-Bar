import SwiftUI

struct StatusMenuView: View {
    let viewModel: StatusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider()
            componentSection
            Divider()
            incidentSection
            Divider()
            footerSection
        }
        .frame(width: 300)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Claude Status")
                .font(.headline)
            Spacer()
            statusBadge
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(overallStatusColor)
                .frame(width: 8, height: 8)
            Text(viewModel.overallStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Components

    private var componentSection: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.components) { component in
                ComponentRow(component: component)
                    .padding(.horizontal, 14)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Incidents

    private var incidentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if viewModel.activeIncidents.isEmpty {
                Text("No active incidents")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            } else {
                Text("Active Incidents")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                ForEach(viewModel.activeIncidents) { incident in
                    IncidentCard(incident: incident)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            if let lastUpdated = viewModel.lastUpdated {
                Text("Last checked: \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
            }

            Divider()

            HStack {
                Button("Open Status Page") {
                    if let url = URL(string: "https://status.claude.com") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
                .font(.caption)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.link)
                .font(.caption)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
        }
        .padding(.top, 6)
    }

    private var overallStatusColor: Color {
        switch viewModel.overallStatus {
        case .none: return .green
        case .minor: return .yellow
        case .major: return .orange
        case .critical: return .red
        }
    }
}
