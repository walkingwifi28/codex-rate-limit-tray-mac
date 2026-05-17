import Foundation

struct UsageFormatter {
    let title = "Codex レート制限"

    private let fiveHourResetFormatter: DateFormatter
    private let weekResetFormatter: DateFormatter
    private let labelWidth = 3

    init(timeZone: TimeZone = .current) {
        fiveHourResetFormatter = UsageFormatter.makeDateFormatter(
            dateFormat: "HH:mm",
            timeZone: timeZone
        )
        weekResetFormatter = UsageFormatter.makeDateFormatter(
            dateFormat: "MM/dd HH:mm",
            timeZone: timeZone
        )
    }

    func displayPercent(for window: UsageWindow) -> Int {
        Int(window.remainingPercent.rounded(.awayFromZero))
    }

    func fiveHourResetString(for date: Date) -> String {
        fiveHourResetFormatter.string(from: date)
    }

    func weekResetString(for date: Date) -> String {
        weekResetFormatter.string(from: date)
    }

    func displayRows(for state: UsageState) -> [String] {
        [
            displayRow(label: "5時間", window: state.fiveHour, resetText: fiveHourResetString(for: state.fiveHour.resetAt)),
            displayRow(label: "週", window: state.week, resetText: weekResetString(for: state.week.resetAt)),
        ]
    }

    func statusSummary(for state: UsageState) -> String {
        "Codexレート制限 : \(displayPercent(for: state.fiveHour))% / \(displayPercent(for: state.week))%"
    }

    private func displayRow(label: String, window: UsageWindow, resetText: String) -> String {
        "\(paddedLabel(label)) : 残り \(displayPercent(for: window))% \(resetText)"
    }

    private func paddedLabel(_ label: String) -> String {
        let paddingCount = max(0, labelWidth - label.count)
        return label + String(repeating: " ", count: paddingCount)
    }

    private static func makeDateFormatter(dateFormat: String, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = dateFormat
        return formatter
    }
}
