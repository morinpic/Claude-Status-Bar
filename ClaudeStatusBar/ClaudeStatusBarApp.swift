import SwiftUI

@main
struct ClaudeStatusBarApp: App {
    @State private var viewModel = StatusViewModel()

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView(viewModel: viewModel)
                .applyLocale(viewModel.selectedLanguage)
        } label: {
            Image(systemName: viewModel.menuBarIcon)
        }
        .menuBarExtraStyle(.window)
        Settings {
            SettingsView(viewModel: viewModel)
                .applyLocale(viewModel.selectedLanguage)
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
