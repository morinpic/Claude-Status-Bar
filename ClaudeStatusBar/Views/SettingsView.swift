import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Bindable var viewModel: StatusViewModel
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }

            Section("Icon Design") {
                let designs = IconDesignType.allCases
                ForEach(designs, id: \.self) { (design: IconDesignType) in
                    HStack {
                        iconPreview(for: design)
                            .frame(width: 24, height: 24)
                        Text(design.displayName)
                        Spacer()
                        if viewModel.selectedIconDesign == design {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedIconDesign = design
                    }
                }
            }

            Section {
                Text("Choose which components trigger desktop notifications when their status changes.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Notifications")
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
        .frame(width: 400, height: 500)
    }

    @ViewBuilder
    private func iconPreview(for design: IconDesignType) -> some View {
        if design == .default {
            Image(systemName: "circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 16))
        } else {
            Image(design.assetName(for: .normal))
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
        }
    }
}
