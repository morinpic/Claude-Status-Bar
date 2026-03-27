import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: StatusViewModel

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            NotificationSettingsTab(viewModel: viewModel)
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
        }
        .frame(width: 360, height: 300)
    }
}
