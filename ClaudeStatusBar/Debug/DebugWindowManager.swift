#if DEBUG
import AppKit
import SwiftUI

@MainActor
final class DebugWindowManager {
    static let shared = DebugWindowManager()
    private var window: NSWindow?

    private init() {}

    func showWindow(viewModel: StatusViewModel) {
        if let existingWindow = window, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        let debugView = DebugWindowView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: debugView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Debug"
        window.contentView = hostingView
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false

        self.window = window
    }
}
#endif
