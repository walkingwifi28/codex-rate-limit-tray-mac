import AppKit
import Foundation
import SwiftUI

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var state: UsageState
    @Published private(set) var isRefreshing = false
    @Published private(set) var menuBarIcon: NSImage

    let formatter: UsageFormatter

    private let authReader: AuthReading
    private let usageClient: WhamUsageFetching
    private let scheduler: RefreshScheduler
    private let iconRenderer: RateLimitIconRenderer

    init(
        authReader: AuthReading,
        usageClient: WhamUsageFetching,
        scheduler: RefreshScheduler,
        formatter: UsageFormatter = UsageFormatter(),
        iconRenderer: RateLimitIconRenderer = RateLimitIconRenderer()
    ) {
        self.authReader = authReader
        self.usageClient = usageClient
        self.scheduler = scheduler
        self.formatter = formatter
        self.iconRenderer = iconRenderer
        self.state = UsageState.success(
            fiveHour: UsageWindow(usedPercent: 0, resetAt: Date()),
            week: UsageWindow(usedPercent: 0, resetAt: Date())
        )
        self.menuBarIcon = iconRenderer.renderIcon(
            state: state,
            appearance: Self.currentAppearance,
            size: 22
        )
    }

    static func production() -> UsageViewModel {
        let viewModel = UsageViewModel(
            authReader: CodexAuthReader(),
            usageClient: WhamUsageClient(),
            scheduler: RefreshScheduler()
        )
        viewModel.start()
        Task {
            await viewModel.refresh()
        }
        return viewModel
    }

    func start() {
        scheduler.start { [weak self] in
            await self?.refresh()
        }
    }

    func stop() {
        scheduler.stop()
    }

    func refresh() async {
        guard !isRefreshing else {
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }

        switch authReader.readAccessToken() {
        case let .success(token):
            state = await usageClient.fetchUsage(accessToken: token)
        case .fileNotFound:
            state = .error(.authFile, ".codex/auth.json がありません")
        case .invalidJSON:
            state = .error(.authFile, "auth.json が不正です")
        case .tokenMissing:
            state = .error(.authFile, "access_token がありません")
        }
        updateMenuBarIcon()
    }

    func updateMenuBarIcon() {
        menuBarIcon = iconRenderer.renderIcon(
            state: state,
            appearance: Self.currentAppearance,
            size: 22
        )
        menuBarIcon.isTemplate = false
        menuBarIcon.accessibilityDescription = formatter.statusSummary(for: state)
    }

    var statusSummary: String {
        formatter.statusSummary(for: state)
    }

    private static var currentAppearance: RateLimitIconRenderer.Appearance {
        let name = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        return name == .darkAqua ? .dark : .light
    }
}
