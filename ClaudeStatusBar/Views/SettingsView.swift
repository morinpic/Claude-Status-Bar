import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Bindable var viewModel: StatusViewModel
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var showingResetConfirmation = false

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

                Picker(selection: $viewModel.selectedLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.localizedDisplayName).tag(language)
                    }
                } label: {
                    Text("Language")
                }
            }

            Section {
                let designs = IconDesignType.allCases
                ForEach(designs, id: \.self) { (design: IconDesignType) in
                    HStack {
                        iconPreview(for: design)
                            .frame(width: 28, height: 28)
                        Text(design.displayName)
                            .font(.body)
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
            } header: {
                Text("Icon Design")
            }

            Section {
                ForEach(viewModel.components) { component in
                    Toggle(
                        component.name,
                        isOn: Binding(
                            get: { viewModel.isComponentNotificationEnabled(component.id) },
                            set: { viewModel.toggleComponentNotification(component.id, enabled: $0) }
                        )
                    )
                }
            } header: {
                Text("Notifications")
            }

            Section {
                HStack {
                    Spacer()
                    Button("Reset All Settings") {
                        showingResetConfirmation = true
                    }
                    Spacer()
                }
            } header: {
                Text("Reset")
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 550)
        .navigationTitle(Text("Settings"))
        .alert("Reset All Settings?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetAllSettings()
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        } message: {
            Text("This will reset icon design, notification settings, and Launch at Login to their defaults.")
        }
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
