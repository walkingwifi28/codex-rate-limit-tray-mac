import SwiftUI

struct SettingsView<Updater: UpdaterServicing>: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var loginItemViewModel: LoginItemViewModel
    @ObservedObject var updaterService: Updater

    var body: some View {
        Form {
            Section {
                Toggle(MenuBarFooterContent.loginItemTitle, isOn: Binding(
                    get: { loginItemViewModel.isEnabled },
                    set: { loginItemViewModel.setEnabled($0) }
                ))

                if let errorMessage = loginItemViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Toggle("自動でアップデートを確認", isOn: $updaterService.automaticallyChecksForUpdates)

                Button("Check for Updates...") {
                    updaterService.checkForUpdates()
                }
                .disabled(!updaterService.canCheckForUpdates)
            }

            Section {
                Text(viewModel.statusSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0")
                        .foregroundStyle(.secondary)
                }

                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .padding(20)
        .onAppear {
            loginItemViewModel.refresh()
        }
    }
}
