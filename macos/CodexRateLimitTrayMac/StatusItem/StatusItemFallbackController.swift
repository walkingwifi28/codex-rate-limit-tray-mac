import AppKit
import SwiftUI

@MainActor
final class StatusItemFallbackController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()

    init(viewModel: UsageViewModel) {
        statusItem.button?.image = viewModel.menuBarIcon
        statusItem.button?.toolTip = viewModel.statusSummary
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 260, height: 320)
        popover.contentViewController = NSHostingController(rootView: MenuBarContentView(viewModel: viewModel))
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
