import SwiftUI

struct StatusMenuView: View {
    @Bindable var viewModel: StatusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider()
            componentSection
            Divider()
            incidentSection
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

    // MARK: - Error

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.error {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
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
        VStack(spacing: 8) {
            HStack {
                if let lastUpdated = viewModel.lastUpdated {
                    Text("Last checked: \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()

                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gear")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open Settings")

                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
            }

            Divider()

            VStack(spacing: 6) {
                Button("Open Status Page") {
                    if let url = URL(string: "https://status.claude.com") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
                .font(.caption)
                .frame(maxWidth: .infinity)

                HStack {
                    Button {
                        if let url = URL(string: "https://github.com/morinpic/Claude-Status-Bar") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Image("github-mark")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open GitHub Repository")

                    Button("Report Bug") {
                        if let url = URL(string: "https://github.com/morinpic/Claude-Status-Bar/issues/new") {
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

    private func openSettings() {
        if #available(macOS 14, *) {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
