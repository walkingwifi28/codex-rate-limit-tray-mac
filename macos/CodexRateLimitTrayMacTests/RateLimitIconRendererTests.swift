import AppKit
import XCTest
@testable import CodexRateLimitTrayMac

final class RateLimitIconRendererTests: XCTestCase {
    func testGeometryKeepsWindowsOuterToInnerRatio() {
        let geometry = RateLimitIconRenderer.calculateGeometry(outerDiameter: 314)

        XCTAssertEqual(geometry.outerDiameter, 314, accuracy: 0.001)
        XCTAssertEqual(geometry.innerDiameter, 200, accuracy: 0.001)
    }

    func testColorsMatchWindowsImplementation() {
        XCTAssertEqual(RateLimitIconRenderer.Colors.outerDisc.hexRGB, "339CFF")
        XCTAssertEqual(RateLimitIconRenderer.Colors.weekNeedle.hexRGB, "FF0000")
        XCTAssertEqual(RateLimitIconRenderer.Colors.lightBackground.hexRGB, "FFFFFF")
        XCTAssertEqual(RateLimitIconRenderer.Colors.lightInnerDisc.hexRGB, "1A1C1F")
        XCTAssertEqual(RateLimitIconRenderer.Colors.darkBackground.hexRGB, "181818")
        XCTAssertEqual(RateLimitIconRenderer.Colors.darkInnerDisc.hexRGB, "FFFFFF")
    }

    func testFullOuterDiscColorsOuterPixel() throws {
        let image = RateLimitIconRenderer().renderIcon(
            fiveHourRemainingPercent: 100,
            weekRemainingPercent: 0,
            weeklyResetAt: Date(timeIntervalSince1970: 7 * 24 * 60 * 60),
            now: Date(timeIntervalSince1970: 0),
            appearance: .dark,
            size: 64
        )

        let color = try image.pixelColor(x: 32, y: 6)

        XCTAssertTrue(color.isClose(to: RateLimitIconRenderer.Colors.outerDisc))
    }

    func testFullInnerDiscColorsCenterPixel() throws {
        let image = RateLimitIconRenderer().renderIcon(
            fiveHourRemainingPercent: 100,
            weekRemainingPercent: 100,
            weeklyResetAt: Date(timeIntervalSince1970: 7 * 24 * 60 * 60),
            now: Date(timeIntervalSince1970: 0),
            appearance: .dark,
            size: 64,
            drawNeedle: false
        )

        let color = try image.pixelColor(x: 32, y: 32)

        XCTAssertTrue(color.isClose(to: RateLimitIconRenderer.Colors.darkInnerDisc))
    }

    func testZeroPercentLeavesUnusedAreaTransparent() throws {
        let image = RateLimitIconRenderer().renderIcon(
            fiveHourRemainingPercent: 0,
            weekRemainingPercent: 0,
            weeklyResetAt: Date(timeIntervalSince1970: 7 * 24 * 60 * 60),
            now: Date(timeIntervalSince1970: 0),
            appearance: .dark,
            size: 64,
            drawNeedle: false
        )

        let color = try image.pixelColor(x: 32, y: 6)

        XCTAssertEqual(color.alphaComponent, 0, accuracy: 0.02)
    }

    func testNeedleProducesRedPixelsAtHalfwayThroughWeeklyWindow() throws {
        let image = RateLimitIconRenderer().renderIcon(
            fiveHourRemainingPercent: 100,
            weekRemainingPercent: 100,
            weeklyResetAt: Date(timeIntervalSince1970: 7 * 24 * 60 * 60),
            now: Date(timeIntervalSince1970: 3.5 * 24 * 60 * 60),
            appearance: .dark,
            size: 64
        )

        let color = try image.pixelColor(x: 32, y: 58)

        XCTAssertGreaterThan(color.redComponent, 0.8)
        XCTAssertLessThan(color.greenComponent, 0.25)
        XCTAssertLessThan(color.blueComponent, 0.25)
    }
}

private extension NSColor {
    var hexRGB: String {
        let color = usingColorSpace(.sRGB)!
        return String(
            format: "%02X%02X%02X",
            Int(round(color.redComponent * 255)),
            Int(round(color.greenComponent * 255)),
            Int(round(color.blueComponent * 255))
        )
    }

    func isClose(to other: NSColor, tolerance: CGFloat = 0.04) -> Bool {
        let lhs = usingColorSpace(.sRGB)!
        let rhs = other.usingColorSpace(.sRGB)!
        return abs(lhs.redComponent - rhs.redComponent) <= tolerance
            && abs(lhs.greenComponent - rhs.greenComponent) <= tolerance
            && abs(lhs.blueComponent - rhs.blueComponent) <= tolerance
            && abs(lhs.alphaComponent - rhs.alphaComponent) <= tolerance
    }
}

private extension NSImage {
    func pixelColor(x: Int, y: Int) throws -> NSColor {
        guard
            let tiffData = tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let color = bitmap.colorAt(x: x, y: y)
        else {
            XCTFail("Could not read image pixel")
            return .clear
        }
        return color.usingColorSpace(.sRGB) ?? color
    }
}
