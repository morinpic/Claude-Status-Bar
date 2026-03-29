import SwiftUI

struct StatusMenuView: View {
    @Bindable var viewModel: StatusViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider()
            componentSection
            Divider()
            incidentSection
            maintenanceSection
            errorSection
            #if DEBUG
            Divider()
            DebugMenuView(viewModel: viewModel)
            #endif
            Divider()
            footerSection
        }
        .frame(width: 300)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "Claude Status")
                    .font(.headline)
                if let lastUpdated = viewModel.lastUpdated {
                    Text(
                        "Last checked: \(lastUpdated.formatted(.dateTime.hour().minute().locale(dateLocale)))",
                        comment: "Label showing the last time status was fetched"
                    )
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.mini)
            }
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
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .glassEffect(.regular, in: .capsule)
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
                    IncidentCard(incident: incident, locale: dateLocale)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Maintenance

    @ViewBuilder
    private var maintenanceSection: some View {
        if !viewModel.scheduledMaintenances.isEmpty {
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("Scheduled Maintenance")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                ForEach(viewModel.scheduledMaintenances) { maintenance in
                    MaintenanceCard(maintenance: maintenance, locale: dateLocale)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Error

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.error {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color(nsColor: .systemYellow))
                        .font(.caption)
                    Text("Connection Error")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                Text(error.localizedDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Button("Retry") {
                    viewModel.refresh()
                }
                .buttonStyle(.link)
                .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider()
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 0) {
            menuItem("Open Status Page") {
                if let url = URL(string: "https://status.claude.com") {
                    NSWorkspace.shared.open(url)
                }
            }

            menuItem("Settings...") {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            }

            Divider()

            menuItem("Quit Claude Status Bar") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func menuItem(_ title: LocalizedStringResource, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    private var dateLocale: Locale {
        viewModel.selectedLanguage.locale ?? .current
    }

    private var overallStatusColor: Color {
        switch viewModel.overallStatus {
        case .none: return Color(nsColor: .systemGreen)
        case .minor: return Color(nsColor: .systemYellow)
        case .major: return Color(nsColor: .systemOrange)
        case .critical: return Color(nsColor: .systemRed)
        }
    }

}
