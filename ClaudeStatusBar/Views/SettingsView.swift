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

            iconDesignSection

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
            Text("This will reset icon design, notification settings, and Launch at Login to their defaults.")
        }
    }

    @ViewBuilder
    private var iconDesignSection: some View {
        Section {
            ForEach(IconDesignType.allCases) { design in
                iconDesignCard(for: design)
            }
        } header: {
            Text("Icon Design")
        }
    }

    @ViewBuilder
    private func iconDesignCard(for design: IconDesignType) -> some View {
        let isSelected = viewModel.selectedIconDesign == design
        VStack {
            HStack {
                ForEach(Array(iconPreviews(for: design).enumerated()), id: \.offset) { _, preview in
                    preview
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectedIconDesign = design
        }
    }

    private func iconPreviews(for design: IconDesignType) -> [AnyView] {
        switch design {
        case .statusIcons:
            let symbols = ["checkmark.circle", "info.circle", "exclamationmark.circle", "xmark.circle", "questionmark.circle"]
            return symbols.map { name in
                AnyView(
                    Image(systemName: name)
                        .font(.system(size: 16))
                )
            }
        case .classic:
            let colors: [Color] = [
                Color(nsColor: .systemGreen),
                Color(nsColor: .systemYellow),
                Color(nsColor: .systemOrange),
                Color(nsColor: .systemRed),
                Color(nsColor: .systemGray),
            ]
            return colors.map { color in
                AnyView(
                    Image(systemName: "circle.fill")
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(color)
                        .font(.system(size: 16))
                )
            }
        case .vibe:
            let emojis = ["😊", "😟", "😰", "💀", "🤔"]
            return emojis.map { emoji in
                AnyView(
                    Text(emoji)
                        .font(.system(size: 16))
                )
            }
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
