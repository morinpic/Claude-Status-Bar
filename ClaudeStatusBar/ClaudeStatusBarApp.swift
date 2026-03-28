import SwiftUI

@main
struct ClaudeStatusBarApp: App {
    @State private var viewModel = StatusViewModel()

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView(viewModel: viewModel)
                .applyLocale(viewModel.selectedLanguage)
        } label: {
            if let nsImage = menuBarCustomIcon {
                Image(nsImage: nsImage)
            } else {
                Image(systemName: viewModel.menuBarIcon)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(menuBarIconColor)
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel)
                .applyLocale(viewModel.selectedLanguage)
        }
    }

    private var menuBarCustomIcon: NSImage? {
        guard let assetName = viewModel.menuBarIconAssetName,
              let nsImage = NSImage(named: assetName) else { return nil }
        nsImage.size = NSSize(width: 18, height: 18)
        nsImage.isTemplate = true
        return nsImage
    }

    private var menuBarIconColor: Color {
        if viewModel.hasError { return .gray }
        switch viewModel.overallStatus {
        case .none: return .green
        case .minor: return .yellow
        case .major: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - View Extension

private extension View {
    @ViewBuilder
    func applyLocale(_ language: AppLanguage) -> some View {
        if let locale = language.locale {
            self.environment(\.locale, locale)
        } else {
            self
        }
    }
}
