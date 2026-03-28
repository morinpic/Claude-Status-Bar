#if DEBUG
import SwiftUI

struct DebugWindowView: View {
    @Bindable var viewModel: StatusViewModel
    @State private var statusPreset: DebugStatusPreset = .live
    @State private var incidentPreset: DebugIncidentPreset = .none
    @State private var componentPreset: DebugComponentPreset = .allOperational
    @State private var errorPreset: DebugErrorPreset = .none
    @State private var isLoadingOverride = false

    var body: some View {
        Form {
            // Polling info
            Section("Polling") {
                HStack {
                    Text("Next poll")
                    Spacer()
                    Text("\(viewModel.pollCountdown)s / \(viewModel.pollInterval)s")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                if viewModel.isDebugMode {
                    HStack {
                        Text("Mode")
                        Spacer()
                        Text("DEBUG")
                            .foregroundStyle(.red)
                            .fontWeight(.bold)
                    }
                }
            }

            // State simulation
            Section("State Simulation") {
                Picker("Status", selection: $statusPreset) {
                    ForEach(DebugStatusPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                Picker("Incidents", selection: $incidentPreset) {
                    ForEach(DebugIncidentPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                Picker("Components", selection: $componentPreset) {
                    ForEach(DebugComponentPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                Picker("Error", selection: $errorPreset) {
                    ForEach(DebugErrorPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                Toggle("Loading", isOn: $isLoadingOverride)

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

                    Button("Reset to Live") {
                        statusPreset = .live
                        incidentPreset = .none
                        componentPreset = .allOperational
                        errorPreset = .none
                        isLoadingOverride = false
                        viewModel.exitDebugMode()
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Notification test
            Section("Notification Test") {
                HStack {
                    Button("📢 Incident") {
                        viewModel.debugSendIncidentNotification()
                    }
                    Button("✅ Recovery") {
                        viewModel.debugSendRecoveryNotification()
                    }
                }
            }

            // Transition simulation
            Section("Simulate Transition") {
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

            // Component notification
            Section("Component Notification") {
                if let firstComponent = viewModel.components.first {
                    Button("\(firstComponent.name): operational → partial_outage") {
                        viewModel.debugSimulateComponentTransition(
                            componentName: firstComponent.name,
                            from: .operational,
                            to: .partialOutage
                        )
                    }
                    Button("\(firstComponent.name): partial_outage → operational") {
                        viewModel.debugSimulateComponentTransition(
                            componentName: firstComponent.name,
                            from: .partialOutage,
                            to: .operational
                        )
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 300, minHeight: 400)
    }
}
#endif
