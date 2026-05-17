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
        static let outerDisc = NSColor(srgbRed: CGFloat(0x33) / 255, green: CGFloat(0x9C) / 255, blue: CGFloat(0xFF) / 255, alpha: 1)
        static let weekNeedle = NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        static let lightBackground = NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        static let lightInnerDisc = NSColor(srgbRed: CGFloat(0x1A) / 255, green: CGFloat(0x1C) / 255, blue: CGFloat(0x1F) / 255, alpha: 1)
        static let darkBackground = NSColor(srgbRed: CGFloat(0x18) / 255, green: CGFloat(0x18) / 255, blue: CGFloat(0x18) / 255, alpha: 1)
        static let darkInnerDisc = NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
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
        let pixelSize = max(1, Int(size.rounded()))
        let geometry = Self.calculateGeometry(outerDiameter: CGFloat(pixelSize))
        let center = CGPoint(x: CGFloat(pixelSize) / 2, y: CGFloat(pixelSize) / 2)
        let outerRadius = geometry.outerDiameter / 2
        let innerRadius = geometry.innerDiameter / 2
        var pixels = Array(repeating: UInt8(0), count: pixelSize * pixelSize * 4)

        fillPie(
            pixels: &pixels,
            pixelSize: pixelSize,
            center: center,
            radius: outerRadius,
            percent: fiveHourRemainingPercent,
            color: Colors.outerDisc.rgba
        )
        fillPie(
            pixels: &pixels,
            pixelSize: pixelSize,
            center: center,
            radius: innerRadius,
            percent: weekRemainingPercent,
            color: appearance.innerDiscColor.rgba
        )

        if drawNeedle {
            drawWeeklyNeedle(
                pixels: &pixels,
                pixelSize: pixelSize,
                center: center,
                radius: outerRadius,
                weeklyResetAt: weeklyResetAt,
                now: now
            )
        }

        return makeImage(pixels: pixels, pixelSize: pixelSize, size: size)
    }

    static func weeklyNeedleAngle(weeklyResetAt: Date, now: Date) -> CGFloat {
        let weekSeconds: TimeInterval = 7 * 24 * 60 * 60
        let remaining = weeklyResetAt.timeIntervalSince(now)
        let progress = max(0, min(1, 1 - remaining / weekSeconds))
        return -90 + CGFloat(progress * 360)
    }

    private func fillPie(
        pixels: inout [UInt8],
        pixelSize: Int,
        center: CGPoint,
        radius: CGFloat,
        percent: Double,
        color: RGBA
    ) {
        let clampedPercent = max(0, min(100, percent))
        guard clampedPercent > 0 else {
            return
        }

        let sweep = CGFloat(clampedPercent / 100) * 2 * .pi
        for y in 0..<pixelSize {
            for x in 0..<pixelSize {
                let dx = CGFloat(x) + 0.5 - center.x
                let dy = CGFloat(y) + 0.5 - center.y
                guard dx * dx + dy * dy <= radius * radius else {
                    continue
                }
                if clampedPercent < 100 {
                    var angle = atan2(dx, -dy)
                    if angle < 0 {
                        angle += 2 * .pi
                    }
                    guard angle <= sweep else {
                        continue
                    }
                }
                setPixel(&pixels, pixelSize: pixelSize, x: x, y: y, color: color)
            }
        }
    }

    private func drawWeeklyNeedle(
        pixels: inout [UInt8],
        pixelSize: Int,
        center: CGPoint,
        radius: CGFloat,
        weeklyResetAt: Date,
        now: Date
    ) {
        let angle = Self.weeklyNeedleAngle(weeklyResetAt: weeklyResetAt, now: now) * .pi / 180
        let end = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
        let width = max(1.5, radius * 0.08)

        for y in 0..<pixelSize {
            for x in 0..<pixelSize {
                let point = CGPoint(x: CGFloat(x) + 0.5, y: CGFloat(y) + 0.5)
                if distanceFromLineSegment(point: point, start: center, end: end) <= width / 2 {
                    setPixel(&pixels, pixelSize: pixelSize, x: x, y: y, color: Colors.weekNeedle.rgba)
                }
            }
        }
    }

    private func setPixel(_ pixels: inout [UInt8], pixelSize: Int, x: Int, y: Int, color: RGBA) {
        let offset = (y * pixelSize + x) * 4
        pixels[offset] = color.red
        pixels[offset + 1] = color.green
        pixels[offset + 2] = color.blue
        pixels[offset + 3] = color.alpha
    }

    private func distanceFromLineSegment(point: CGPoint, start: CGPoint, end: CGPoint) -> CGFloat {
        let vx = end.x - start.x
        let vy = end.y - start.y
        let wx = point.x - start.x
        let wy = point.y - start.y
        let lengthSquared = vx * vx + vy * vy
        guard lengthSquared > 0 else {
            return hypot(point.x - start.x, point.y - start.y)
        }
        let t = max(0, min(1, (wx * vx + wy * vy) / lengthSquared))
        let projection = CGPoint(x: start.x + t * vx, y: start.y + t * vy)
        return hypot(point.x - projection.x, point.y - projection.y)
    }

    private func makeImage(pixels: [UInt8], pixelSize: Int, size: CGFloat) -> NSImage {
        let data = Data(pixels)
        let provider = CGDataProvider(data: data as CFData)!
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGBitmapInfo(rawValue:
            CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        )
        let cgImage = CGImage(
            width: pixelSize,
            height: pixelSize,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: pixelSize * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
        return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
    }
}

private struct RGBA {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
}

private extension NSColor {
    var rgba: RGBA {
        let color = usingColorSpace(.sRGB)!
        return RGBA(
            red: UInt8(round(color.redComponent * 255)),
            green: UInt8(round(color.greenComponent * 255)),
            blue: UInt8(round(color.blueComponent * 255)),
            alpha: UInt8(round(color.alphaComponent * 255))
        )
    }
}
