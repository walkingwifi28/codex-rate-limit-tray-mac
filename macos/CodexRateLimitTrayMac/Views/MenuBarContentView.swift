import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var loginItemViewModel: LoginItemViewModel
    private let footerActions: MenuBarFooterActions

    init(
        viewModel: UsageViewModel,
        loginItemViewModel: LoginItemViewModel,
        footerActions: MenuBarFooterActions = MenuBarFooterActions(quitApplication: { NSApp.terminate(nil) })
    ) {
        self.viewModel = viewModel
        self.loginItemViewModel = loginItemViewModel
        self.footerActions = footerActions
    }

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
                    HStack(spacing: UsageRowLayout.itemSpacing) {
                        Text(row.label)
                            .frame(width: UsageRowLayout.labelWidth, alignment: .leading)
                        Text(row.separator)
                        Text(row.remainingLabel)

                        Text(row.percentText)
                            .frame(width: UsageRowLayout.percentWidth, alignment: .trailing)

                        if row.resetDateText.isEmpty {
                            Color.clear
                                .frame(width: UsageRowLayout.resetDateWidth)
                        } else {
                            Text(row.resetDateText)
                                .frame(width: UsageRowLayout.resetDateWidth, alignment: .trailing)
                        }

                        Text(row.resetTimeText)
                            .frame(width: UsageRowLayout.resetTimeWidth, alignment: .trailing)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
            .font(.system(.callout, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: true, vertical: false)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Button {
                    loginItemViewModel.setEnabled(!loginItemViewModel.isEnabled)
                } label: {
                    HStack(spacing: MenuBarFooterContent.itemSpacing) {
                        ZStack {
                            if loginItemViewModel.isEnabled {
                                Image(systemName: MenuBarFooterContent.selectedIndicatorSystemName)
                                    .font(.system(size: MenuBarFooterContent.menuItemFontSize))
                            }
                        }
                        .frame(width: MenuBarFooterContent.leadingIndicatorWidth)

                        Text(MenuBarFooterContent.loginItemTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if let errorMessage = loginItemViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    footerActions.quit()
                } label: {
                    HStack(spacing: MenuBarFooterContent.itemSpacing) {
                        Color.clear
                            .frame(width: MenuBarFooterContent.leadingIndicatorWidth)

                        Text(MenuBarFooterContent.quitTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .font(.system(size: MenuBarFooterContent.menuItemFontSize))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .onAppear {
            loginItemViewModel.refresh()
            Task { await viewModel.refresh() }
        }
    }
}

struct MenuBarFooterContent {
    static let loginItemTitle = "ログイン時の自動起動"
    static let quitTitle = "Codexレート制限を終了"
    static let selectedIndicatorSystemName = "checkmark"
    static let leadingIndicatorWidth: CGFloat = 24
    static let itemSpacing: CGFloat = 0
    static let menuItemFontSize = NSFont.systemFontSize
}

struct MenuBarFooterActions {
    let quitApplication: () -> Void

    func quit() {
        quitApplication()
    }
}

private enum UsageRowLayout {
    static let itemSpacing: CGFloat = 6
    static let labelWidth: CGFloat = 42
    static let percentWidth: CGFloat = 30
    static let resetDateWidth: CGFloat = 48
    static let resetTimeWidth: CGFloat = 48
}
