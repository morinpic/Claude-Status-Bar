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
                // Status Icons mode: use NSImage with explicit pointSize to control
                // the icon size, since .font() is ignored in MenuBarExtra labels.
                Image(nsImage: statusIconImage(symbolName: viewModel.menuBarIcon))
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

private func statusIconImage(symbolName: String) -> NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    guard let baseImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else {
        return NSImage()
    }
    let image = NSImage(size: baseImage.size, flipped: false) { rect in
        baseImage.draw(in: rect)
        return true
    }
    image.isTemplate = true
    return image
}

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
