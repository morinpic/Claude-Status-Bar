import SwiftUI

@main
struct ClaudeStatusBarApp: App {
    @State private var viewModel = StatusViewModel()

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView(viewModel: viewModel)
                .applyLocale(viewModel.selectedLanguage)
        } label: {
            if let nsColor = viewModel.menuBarIconNSColor {
                // Classic mode: MenuBarExtra treats SF Symbols as template images,
                // so .foregroundStyle() is ignored. Draw a colored circle via NSBezierPath
                // with isTemplate = false to ensure the color is rendered correctly.
                Image(nsImage: coloredCircleImage(color: nsColor))
            } else {
                Image(systemName: viewModel.menuBarIcon)
                    .font(.system(size: 24))
            }
        }
        .menuBarExtraStyle(.window)
        Settings {
            SettingsView(viewModel: viewModel)
                .applyLocale(viewModel.selectedLanguage)
        }
    }
}

// MARK: - Helpers

private func coloredCircleImage(color: NSColor) -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size, flipped: false) { rect in
        let circleRect = rect.insetBy(dx: 2, dy: 2)
        let path = NSBezierPath(ovalIn: circleRect)
        color.setFill()
        path.fill()
        return true
    }
    image.isTemplate = false
    return image
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
