import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        VStack(spacing: 14) {
            Text(viewModel.formatter.title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)

            if viewModel.state.hasError {
                VStack(spacing: 6) {
                    Text("取得できません")
                        .font(.title3.weight(.semibold))
                    Text(viewModel.state.errorMessage ?? "レスポンスが不正です")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 132)
            } else {
                UsageGraphView(state: viewModel.state)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.formatter.displayRows(for: viewModel.state), id: \.self) { row in
                    Text(row)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Divider()

            HStack(spacing: 10) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isRefreshing)
                .help("更新")

                Spacer()

                Button {
                    showSettings()
                } label: {
                    Image(systemName: "gearshape")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .help("設定")

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .help("終了")
            }
        }
        .padding(16)
        .onAppear {
            Task { await viewModel.refresh() }
        }
    }

    private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
