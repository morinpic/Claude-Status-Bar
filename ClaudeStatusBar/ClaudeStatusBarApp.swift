import SwiftUI

@main
struct ClaudeStatusBarApp: App {
    @State private var viewModel = StatusViewModel()

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView(viewModel: viewModel)
        } label: {
            if let assetName = viewModel.menuBarIconAssetName {
                Image(assetName)
                    .renderingMode(.original)
            } else {
                Image(systemName: viewModel.menuBarIcon)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(menuBarIconColor)
            }
        }
        .menuBarExtraStyle(.window)
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
