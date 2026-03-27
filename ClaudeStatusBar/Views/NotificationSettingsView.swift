import SwiftUI

struct NotificationSettingsView: View {
    @Bindable var viewModel: StatusViewModel
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Notification Settings")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(viewModel.components) { component in
                        ComponentNotificationToggle(
                            componentName: component.name,
                            isEnabled: viewModel.isComponentNotificationEnabled(component.id),
                            onToggle: { enabled in
                                viewModel.toggleComponentNotification(component.id, enabled: enabled)
                            }
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
    }
}

struct ComponentNotificationToggle: View {
    let componentName: String
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    @State private var toggleState: Bool

    init(componentName: String, isEnabled: Bool, onToggle: @escaping (Bool) -> Void) {
        self.componentName = componentName
        self.isEnabled = isEnabled
        self.onToggle = onToggle
        self._toggleState = State(initialValue: isEnabled)
    }

    var body: some View {
        Toggle(componentName, isOn: $toggleState)
            .toggleStyle(.switch)
            .controlSize(.mini)
            .font(.caption)
            .onChange(of: toggleState) { _, newValue in
                onToggle(newValue)
            }
    }
}
