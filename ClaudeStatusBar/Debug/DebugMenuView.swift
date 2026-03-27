#if DEBUG
import SwiftUI

struct DebugMenuView: View {
    @Bindable var viewModel: StatusViewModel
    @State private var isExpanded = false
    @State private var statusPreset: DebugStatusPreset = .live
    @State private var incidentPreset: DebugIncidentPreset = .none
    @State private var componentPreset: DebugComponentPreset = .allOperational
    @State private var errorPreset: DebugErrorPreset = .none
    @State private var isLoadingOverride = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー（タップで展開/折りたたみ）
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
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
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Status
                    Picker("Status", selection: $statusPreset) {
                        ForEach(DebugStatusPreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)

                    // Incidents
                    Picker("Incidents", selection: $incidentPreset) {
                        ForEach(DebugIncidentPreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)

                    // Components
                    Picker("Components", selection: $componentPreset) {
                        ForEach(DebugComponentPreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)

                    // Error
                    Picker("Error", selection: $errorPreset) {
                        ForEach(DebugErrorPreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)

                    // Loading
                    Toggle("Loading", isOn: $isLoadingOverride)
                        .toggleStyle(.switch)
                        .controlSize(.small)

                    // Apply / Reset
                    HStack {
                        Button("Apply") {
                            viewModel.applyDebugState(
                                statusPreset: statusPreset,
                                incidentPreset: incidentPreset,
                                componentPreset: componentPreset,
                                errorPreset: errorPreset,
                                isLoadingOverride: isLoadingOverride
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("Reset to Live") {
                            statusPreset = .live
                            incidentPreset = .none
                            componentPreset = .allOperational
                            errorPreset = .none
                            isLoadingOverride = false
                            viewModel.exitDebugMode()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Text("Notification Test")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button("📢 Incident") {
                            viewModel.debugSendIncidentNotification()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button("✅ Recovery") {
                            viewModel.debugSendRecoveryNotification()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Text("Simulate Transition")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Button("none → minor") {
                            viewModel.debugSimulateTransition(from: .none, to: .minor)
                        }
                        Button("none → major") {
                            viewModel.debugSimulateTransition(from: .none, to: .major)
                        }
                        Button("none → critical") {
                            viewModel.debugSimulateTransition(from: .none, to: .critical)
                        }
                        Button("minor → none (recovery)") {
                            viewModel.debugSimulateTransition(from: .minor, to: .none)
                        }
                        Button("major → none (recovery)") {
                            viewModel.debugSimulateTransition(from: .major, to: .none)
                        }
                    }
                    .buttonStyle(.link)
                    .font(.caption)

                    Text("Component Notification")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Button("Claude API: operational → partial_outage") {
                        viewModel.debugSimulateComponentTransition(
                            componentName: "Claude API",
                            from: .operational,
                            to: .partialOutage
                        )
                    }
                    .buttonStyle(.link)
                    .font(.caption)

                    Button("Claude API: partial_outage → operational") {
                        viewModel.debugSimulateComponentTransition(
                            componentName: "Claude API",
                            from: .partialOutage,
                            to: .operational
                        )
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
    }
}
#endif
