#if DEBUG
import SwiftUI

struct DebugMenuView: View {
    @Bindable var viewModel: StatusViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Text("🐛 Debug")
                    .font(.caption)
                    .fontWeight(.semibold)
                if viewModel.isDebugMode {
                    Text("ON")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                Spacer()
                Text("⏱ \(viewModel.pollCountdown)s / \(viewModel.pollInterval)s")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            // Status — all buttons in one row
            sectionLabel("Status")
            FlowButtons {
                statusButton("Live", preset: .live)
                statusButton("OK", preset: .operational)
                statusButton("Minor", preset: .minor)
                statusButton("Major", preset: .major)
                statusButton("Critical", preset: .critical)
            }

            // Incidents
            sectionLabel("Incidents")
            FlowButtons {
                incidentButton("None", preset: .none)
                incidentButton("1 Minor", preset: .singleMinor)
                incidentButton("1 Major", preset: .singleMajor)
                incidentButton("Multiple", preset: .multiple)
            }

            // Components
            sectionLabel("Components")
            FlowButtons {
                componentButton("All OK", preset: .allOperational)
                componentButton("Degraded", preset: .someDegraded)
                componentButton("Partial", preset: .partialOutage)
                componentButton("Major", preset: .majorOutage)
                componentButton("Mixed", preset: .mixed)
            }

            // Error
            sectionLabel("Error")
            FlowButtons {
                errorButton("None", preset: .none)
                errorButton("Network", preset: .networkError)
                errorButton("HTTP 500", preset: .httpError)
            }

            // Loading toggle
            Toggle("Loading", isOn: Binding(
                get: { viewModel.isLoading },
                set: { newValue in
                    viewModel.applyDebugState(
                        statusPreset: .operational,
                        incidentPreset: .none,
                        componentPreset: .allOperational,
                        errorPreset: .none,
                        isLoadingOverride: newValue
                    )
                }
            ))
            .toggleStyle(.switch)
            .controlSize(.mini)
            .font(.caption)

            Divider()

            // Notifications
            sectionLabel("Notifications")
            HStack(spacing: 4) {
                Button("📢 Incident") { viewModel.debugSendIncidentNotification() }
                Button("✅ Recovery") { viewModel.debugSendRecoveryNotification() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            // Transitions
            sectionLabel("Transitions")
            HStack(spacing: 4) {
                Button("→ minor") { viewModel.debugSimulateTransition(from: .none, to: .minor) }
                Button("→ major") { viewModel.debugSimulateTransition(from: .none, to: .major) }
                Button("→ critical") { viewModel.debugSimulateTransition(from: .none, to: .critical) }
                Button("→ recover") { viewModel.debugSimulateTransition(from: .major, to: .none) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            // Component transitions
            if let first = viewModel.components.first {
                sectionLabel("Component")
                HStack(spacing: 4) {
                    Button("→ outage") {
                        viewModel.debugSimulateComponentTransition(
                            componentName: first.name, from: .operational, to: .partialOutage
                        )
                    }
                    Button("→ recover") {
                        viewModel.debugSimulateComponentTransition(
                            componentName: first.name, from: .partialOutage, to: .operational
                        )
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            // Reset
            Divider()
            Button("Reset to Live") {
                viewModel.exitDebugMode()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundStyle(.red)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }

    // Status buttons that apply immediately on tap
    private func statusButton(_ label: String, preset: DebugStatusPreset) -> some View {
        Button(label) {
            viewModel.applyDebugState(
                statusPreset: preset,
                incidentPreset: .none,
                componentPreset: .allOperational,
                errorPreset: .none,
                isLoadingOverride: false
            )
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func incidentButton(_ label: String, preset: DebugIncidentPreset) -> some View {
        Button(label) {
            viewModel.applyDebugState(
                statusPreset: .operational,
                incidentPreset: preset,
                componentPreset: .allOperational,
                errorPreset: .none,
                isLoadingOverride: false
            )
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func componentButton(_ label: String, preset: DebugComponentPreset) -> some View {
        Button(label) {
            viewModel.applyDebugState(
                statusPreset: .operational,
                incidentPreset: .none,
                componentPreset: preset,
                errorPreset: .none,
                isLoadingOverride: false
            )
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func errorButton(_ label: String, preset: DebugErrorPreset) -> some View {
        Button(label) {
            viewModel.applyDebugState(
                statusPreset: .operational,
                incidentPreset: .none,
                componentPreset: .allOperational,
                errorPreset: preset,
                isLoadingOverride: false
            )
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

// Simple flow layout for buttons
private struct FlowButtons<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 4) {
            content
        }
    }
}
#endif
