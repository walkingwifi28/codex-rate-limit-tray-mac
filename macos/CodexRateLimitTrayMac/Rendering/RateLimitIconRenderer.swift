import AppKit
import Foundation

struct RateLimitIconRenderer {
    private static let samplesPerPixel = 4

    struct Geometry: Equatable {
        let outerDiameter: CGFloat
        let innerDiameter: CGFloat
    }

    enum Colors {
        static let outerDisc = NSColor(srgbRed: CGFloat(0x33) / 255, green: CGFloat(0x9C) / 255, blue: CGFloat(0xFF) / 255, alpha: 1)
        static let weekNeedle = NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
    }

    static func calculateGeometry(outerDiameter: CGFloat) -> Geometry {
        Geometry(outerDiameter: outerDiameter, innerDiameter: outerDiameter * 200 / 314)
    }

    func renderIcon(
        state: UsageState,
        now: Date = Date(),
        size: CGFloat = 22
    ) -> NSImage {
        renderIcon(
            weekRemainingPercent: state.week.remainingPercent,
            weeklyResetAt: state.week.resetAt,
            now: now,
            size: size
        )
    }

    func renderIcon(
        weekRemainingPercent: Double,
        weeklyResetAt: Date,
        now: Date,
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
            innerRadius: innerRadius,
            radius: outerRadius,
            remainingPercent: weekRemainingPercent,
            color: Colors.outerDisc.rgba
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
        innerRadius: CGFloat,
        radius: CGFloat,
        remainingPercent: Double,
        color: RGBA
    ) {
        let clampedRemainingPercent = max(0, min(100, remainingPercent))
        guard clampedRemainingPercent < 100 else {
            return
        }

        let usedSweep = CGFloat((100 - clampedRemainingPercent) / 100) * 2 * .pi
        let innerRadiusSquared = innerRadius * innerRadius
        for y in 0..<pixelSize {
            for x in 0..<pixelSize {
                let coverage = coverageForPixel(x: x, y: y) { point in
                    let dx = point.x - center.x
                    let dy = point.y - center.y
                    let distanceSquared = dx * dx + dy * dy
                    guard distanceSquared <= radius * radius && distanceSquared >= innerRadiusSquared else {
                        return false
                    }
                    if clampedRemainingPercent > 0 {
                        var angle = atan2(dx, -dy)
                        if angle < 0 {
                            angle += 2 * .pi
                        }
                        return angle <= usedSweep
                    }
                    return true
                }
                if coverage > 0 {
                    blendPixel(&pixels, pixelSize: pixelSize, x: x, y: y, color: color, coverage: coverage)
                }
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
                let coverage = coverageForPixel(x: x, y: y) { point in
                    distanceFromLineSegment(point: point, start: center, end: end) <= width / 2
                }
                if coverage > 0 {
                    blendPixel(
                        &pixels,
                        pixelSize: pixelSize,
                        x: x,
                        y: y,
                        color: Colors.weekNeedle.rgba,
                        coverage: coverage
                    )
                }
            }
        }
    }

    private func coverageForPixel(x: Int, y: Int, contains: (CGPoint) -> Bool) -> CGFloat {
        let samples = Self.samplesPerPixel
        var coveredSamples = 0

        for sampleY in 0..<samples {
            for sampleX in 0..<samples {
                let point = CGPoint(
                    x: CGFloat(x) + (CGFloat(sampleX) + 0.5) / CGFloat(samples),
                    y: CGFloat(y) + (CGFloat(sampleY) + 0.5) / CGFloat(samples)
                )
                if contains(point) {
                    coveredSamples += 1
                }
            }
        }

        return CGFloat(coveredSamples) / CGFloat(samples * samples)
    }

    private func blendPixel(
        _ pixels: inout [UInt8],
        pixelSize: Int,
        x: Int,
        y: Int,
        color: RGBA,
        coverage: CGFloat
    ) {
        let offset = (y * pixelSize + x) * 4
        let sourceAlpha = Double(color.alpha) / 255 * Double(coverage)
        let inverseSourceAlpha = 1 - sourceAlpha

        let destinationRed = Double(pixels[offset]) / 255
        let destinationGreen = Double(pixels[offset + 1]) / 255
        let destinationBlue = Double(pixels[offset + 2]) / 255
        let destinationAlpha = Double(pixels[offset + 3]) / 255

        let sourceRed = Double(color.red) / 255 * sourceAlpha
        let sourceGreen = Double(color.green) / 255 * sourceAlpha
        let sourceBlue = Double(color.blue) / 255 * sourceAlpha

        pixels[offset] = UInt8(round(max(0, min(1, sourceRed + destinationRed * inverseSourceAlpha)) * 255))
        pixels[offset + 1] = UInt8(round(max(0, min(1, sourceGreen + destinationGreen * inverseSourceAlpha)) * 255))
        pixels[offset + 2] = UInt8(round(max(0, min(1, sourceBlue + destinationBlue * inverseSourceAlpha)) * 255))
        pixels[offset + 3] = UInt8(round(max(0, min(1, sourceAlpha + destinationAlpha * inverseSourceAlpha)) * 255))
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
