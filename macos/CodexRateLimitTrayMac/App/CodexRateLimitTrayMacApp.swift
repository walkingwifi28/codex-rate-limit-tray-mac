import SwiftUI

@main
struct CodexRateLimitTrayMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var usageViewModel = UsageViewModel.production()
    @StateObject private var loginItemViewModel = LoginItemViewModel(service: LoginItemService())
    @StateObject private var updaterService = UpdaterService()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: usageViewModel)
                .frame(width: 260)
        } label: {
            Image(nsImage: usageViewModel.menuBarIcon)
                .help(usageViewModel.statusSummary)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(
                viewModel: usageViewModel,
                loginItemViewModel: loginItemViewModel,
                updaterService: updaterService
            )
        }
    }
}
