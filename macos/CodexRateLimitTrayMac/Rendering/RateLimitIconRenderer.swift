import AppKit
import Foundation

struct RateLimitIconRenderer {
    enum Appearance {
        case light
        case dark

        var innerDiscColor: NSColor {
            switch self {
            case .light:
                return Colors.lightInnerDisc
            case .dark:
                return Colors.darkInnerDisc
            }
        }
    }

    struct Geometry: Equatable {
        let outerDiameter: CGFloat
        let innerDiameter: CGFloat
    }

    enum Colors {
        static let outerDisc = NSColor(calibratedRed: CGFloat(0x33) / 255, green: CGFloat(0x9C) / 255, blue: CGFloat(0xFF) / 255, alpha: 1)
        static let weekNeedle = NSColor(calibratedRed: 1, green: 0, blue: 0, alpha: 1)
        static let lightBackground = NSColor(calibratedWhite: 1, alpha: 1)
        static let lightInnerDisc = NSColor(calibratedRed: CGFloat(0x1A) / 255, green: CGFloat(0x1C) / 255, blue: CGFloat(0x1F) / 255, alpha: 1)
        static let darkBackground = NSColor(calibratedWhite: CGFloat(0x18) / 255, alpha: 1)
        static let darkInnerDisc = NSColor(calibratedWhite: 1, alpha: 1)
    }

    static func calculateGeometry(outerDiameter: CGFloat) -> Geometry {
        Geometry(outerDiameter: outerDiameter, innerDiameter: outerDiameter * 200 / 314)
    }

    func renderIcon(
        state: UsageState,
        now: Date = Date(),
        appearance: Appearance,
        size: CGFloat = 22
    ) -> NSImage {
        renderIcon(
            fiveHourRemainingPercent: state.fiveHour.remainingPercent,
            weekRemainingPercent: state.week.remainingPercent,
            weeklyResetAt: state.week.resetAt,
            now: now,
            appearance: appearance,
            size: size
        )
    }

    func renderIcon(
        fiveHourRemainingPercent: Double,
        weekRemainingPercent: Double,
        weeklyResetAt: Date,
        now: Date,
        appearance: Appearance,
        size: CGFloat,
        drawNeedle: Bool = true
    ) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: size, height: size).fill()

        let geometry = Self.calculateGeometry(outerDiameter: size)
        let center = NSPoint(x: size / 2, y: size / 2)
        let outerRadius = geometry.outerDiameter / 2
        let innerRadius = geometry.innerDiameter / 2

        drawPie(
            center: center,
            radius: outerRadius,
            percent: fiveHourRemainingPercent,
            color: Colors.outerDisc
        )
        drawPie(
            center: center,
            radius: innerRadius,
            percent: weekRemainingPercent,
            color: appearance.innerDiscColor
        )

        if drawNeedle {
            drawWeeklyNeedle(center: center, radius: outerRadius, weeklyResetAt: weeklyResetAt, now: now)
        }

        return image
    }

    static func weeklyNeedleAngle(weeklyResetAt: Date, now: Date) -> CGFloat {
        let weekSeconds: TimeInterval = 7 * 24 * 60 * 60
        let remaining = weeklyResetAt.timeIntervalSince(now)
        let progress = max(0, min(1, 1 - remaining / weekSeconds))
        return 90 - CGFloat(progress * 360)
    }

    private func drawPie(center: NSPoint, radius: CGFloat, percent: Double, color: NSColor) {
        let clampedPercent = max(0, min(100, percent))
        guard clampedPercent > 0 else {
            return
        }

        color.setFill()
        if clampedPercent >= 100 {
            NSBezierPath(ovalIn: NSRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )).fill()
            return
        }

        let startAngle: CGFloat = 90
        let endAngle = startAngle - CGFloat(clampedPercent / 100 * 360)
        let path = NSBezierPath()
        path.move(to: center)
        path.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        path.close()
        path.fill()
    }

    private func drawWeeklyNeedle(center: NSPoint, radius: CGFloat, weeklyResetAt: Date, now: Date) {
        let angle = Self.weeklyNeedleAngle(weeklyResetAt: weeklyResetAt, now: now) * .pi / 180
        let end = NSPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )

        let path = NSBezierPath()
        path.lineWidth = max(1.5, radius * 0.08)
        path.lineCapStyle = .round
        path.move(to: center)
        path.line(to: end)
        Colors.weekNeedle.setStroke()
        path.stroke()
    }
}
