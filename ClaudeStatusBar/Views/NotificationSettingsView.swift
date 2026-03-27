import SwiftUI

struct NotificationSettingsTab: View {
    @Bindable var viewModel: StatusViewModel

    var body: some View {
        Form {
            Section {
                Text("Choose which components trigger desktop notifications when their status changes.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Components") {
                ForEach(viewModel.components) { component in
                    Toggle(
                        component.name,
                        isOn: Binding(
                            get: { viewModel.isComponentNotificationEnabled(component.id) },
                            set: { viewModel.toggleComponentNotification(component.id, enabled: $0) }
                        )
                    )
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
