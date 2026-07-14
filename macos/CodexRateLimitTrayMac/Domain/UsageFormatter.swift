import Foundation

struct UsageDisplayRow: Equatable, Hashable {
    let label: String
    let separator: String
    let remainingLabel: String
    let percentText: String
    let resetDateText: String
    let resetTimeText: String
}

struct UsageFormatter {
    let title = "Codex レート制限"

    private let weekResetDateFormatter: DateFormatter
    private let weekResetTimeFormatter: DateFormatter

    init(timeZone: TimeZone = .current) {
        weekResetDateFormatter = UsageFormatter.makeDateFormatter(
            dateFormat: "MM/dd",
            timeZone: timeZone
        )
        weekResetTimeFormatter = UsageFormatter.makeDateFormatter(
            dateFormat: "HH:mm",
            timeZone: timeZone
        )
    }

    func displayPercent(for window: UsageWindow) -> Int {
        Int(window.remainingPercent.rounded(.awayFromZero))
    }

    func weekResetString(for date: Date) -> String {
        "\(weekResetDateString(for: date)) \(weekResetTimeString(for: date))"
    }

    func weekResetDateString(for date: Date) -> String {
        weekResetDateFormatter.string(from: date)
    }

    func weekResetTimeString(for date: Date) -> String {
        weekResetTimeFormatter.string(from: date)
    }

    func displayRows(for state: UsageState) -> [UsageDisplayRow] {
        [
            displayRow(
                label: "週",
                window: state.week,
                resetDateText: weekResetDateString(for: state.week.resetAt),
                resetTimeText: weekResetTimeString(for: state.week.resetAt)
            ),
        ]
    }

    func statusSummary(for state: UsageState) -> String {
        "Codexレート制限 : \(displayPercent(for: state.week))%"
    }

    private func displayRow(label: String, window: UsageWindow, resetDateText: String, resetTimeText: String) -> UsageDisplayRow {
        UsageDisplayRow(
            label: label,
            separator: ":",
            remainingLabel: "残り",
            percentText: "\(displayPercent(for: window))%",
            resetDateText: resetDateText,
            resetTimeText: resetTimeText
        )
    }

    private static func makeDateFormatter(dateFormat: String, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = dateFormat
        return formatter
    }
}
