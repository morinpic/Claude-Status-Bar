import AppKit
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
        .onAppear {
            updateWindowTitle()
        }
        .onChange(of: viewModel.selectedLanguage) { _, _ in
            updateWindowTitle()
        }
        .alert("Reset All Settings?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetAllSettings()
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        } message: {
            Text("This will reset notification settings and Launch at Login to their defaults.")
        }
    }

    private func settingsTitle() -> String {
        switch viewModel.selectedLanguage {
        case .en: return "Settings"
        case .ja: return "設定"
        case .system:
            return Locale.current.language.languageCode?.identifier == "ja" ? "設定" : "Settings"
        }
    }

    private func updateWindowTitle() {
        Task { @MainActor in
            for window in NSApplication.shared.windows {
                if window.identifier?.rawValue.contains("Settings") == true ||
                   window.title == "設定" || window.title == "Settings" {
                    window.title = settingsTitle()
                    break
                }
            }
        }
    }

}
