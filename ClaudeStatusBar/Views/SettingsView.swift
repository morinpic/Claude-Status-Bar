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
                ForEach(IconDesignType.allCases) { design in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(verbatim: design.displayName)
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            if viewModel.selectedIconDesign == design {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                        HStack(spacing: 16) {
                            ForEach(iconPreviewItems(for: design), id: \.label) { item in
                                VStack(spacing: 4) {
                                    item.icon
                                        .frame(width: 24, height: 24)
                                    Text(verbatim: item.label)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
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

    private struct IconPreviewItem {
        let icon: AnyView
        let label: String
    }

    private func iconPreviewItems(for design: IconDesignType) -> [IconPreviewItem] {
        switch design {
        case .statusIcons:
            return [
                IconPreviewItem(
                    icon: AnyView(Image(systemName: "checkmark.circle").font(.system(size: 16))),
                    label: "OK"
                ),
                IconPreviewItem(
                    icon: AnyView(Image(systemName: "info.circle").font(.system(size: 16))),
                    label: "Minor"
                ),
                IconPreviewItem(
                    icon: AnyView(Image(systemName: "exclamationmark.circle").font(.system(size: 16))),
                    label: "Major"
                ),
                IconPreviewItem(
                    icon: AnyView(Image(systemName: "xmark.circle").font(.system(size: 16))),
                    label: "Critical"
                ),
                IconPreviewItem(
                    icon: AnyView(Image(systemName: "questionmark.circle").font(.system(size: 16))),
                    label: "Error"
                ),
            ]
        case .classic:
            let colors: [(Color, String)] = [
                (Color(nsColor: .systemGreen), "OK"),
                (Color(nsColor: .systemYellow), "Minor"),
                (Color(nsColor: .systemOrange), "Major"),
                (Color(nsColor: .systemRed), "Critical"),
                (Color(nsColor: .systemGray), "Error"),
            ]
            return colors.map { color, label in
                IconPreviewItem(
                    icon: AnyView(
                        Image(systemName: "circle.fill")
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(color)
                            .font(.system(size: 16))
                    ),
                    label: label
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
