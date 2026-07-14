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
    }

    func testFullRemainingOuterDiscLeavesOuterPixelTransparent() throws {
        let image = RateLimitIconRenderer().renderIcon(
            weekRemainingPercent: 100,
            weeklyResetAt: Date(timeIntervalSince1970: 7 * 24 * 60 * 60),
            now: Date(timeIntervalSince1970: 0),
            size: 64,
            drawNeedle: false
        )

        let color = try image.pixelColor(x: 32, y: 6)

        XCTAssertEqual(color.alphaComponent, 0, accuracy: 0.02)
    }

    func testFullRemainingRingLeavesCenterPixelTransparent() throws {
        let image = RateLimitIconRenderer().renderIcon(
            weekRemainingPercent: 100,
            weeklyResetAt: Date(timeIntervalSince1970: 7 * 24 * 60 * 60),
            now: Date(timeIntervalSince1970: 0),
            size: 64,
            drawNeedle: false
        )

        let color = try image.pixelColor(x: 32, y: 32)

        XCTAssertEqual(color.alphaComponent, 0, accuracy: 0.02)
    }

    func testZeroRemainingPercentColorsOuterPixel() throws {
        let image = RateLimitIconRenderer().renderIcon(
            weekRemainingPercent: 0,
            weeklyResetAt: Date(timeIntervalSince1970: 7 * 24 * 60 * 60),
            now: Date(timeIntervalSince1970: 0),
            size: 64,
            drawNeedle: false
        )

        let color = try image.pixelColor(x: 32, y: 6)

        XCTAssertTrue(
            color.isClose(to: RateLimitIconRenderer.Colors.outerDisc),
            "got \(color.hexRGB) alpha \(color.alphaComponent)"
        )
    }

    func testOuterRingDoesNotColorTransparentInnerArea() throws {
        let image = RateLimitIconRenderer().renderIcon(
            weekRemainingPercent: 0,
            weeklyResetAt: Date(timeIntervalSince1970: 7 * 24 * 60 * 60),
            now: Date(timeIntervalSince1970: 0),
            size: 64,
            drawNeedle: false
        )

        let centerColor = try image.pixelColor(x: 32, y: 32)

        XCTAssertEqual(centerColor.alphaComponent, 0, accuracy: 0.02)
    }

    func testOuterUsedArcEndsAtUsedPercentage() throws {
        let image = RateLimitIconRenderer().renderIcon(
            weekRemainingPercent: 78,
            weeklyResetAt: Date(timeIntervalSince1970: 7 * 24 * 60 * 60),
            now: Date(timeIntervalSince1970: 0),
            size: 64,
            drawNeedle: false
        )

        let usedPortionColor = try image.pixelColor(x: 46, y: 13)
        let remainingPortionColor = try image.pixelColor(x: 32, y: 56)

        XCTAssertTrue(
            usedPortionColor.isClose(to: RateLimitIconRenderer.Colors.outerDisc),
            "got \(usedPortionColor.hexRGB) alpha \(usedPortionColor.alphaComponent)"
        )
        XCTAssertEqual(remainingPortionColor.alphaComponent, 0, accuracy: 0.02)
    }

    func testOuterDiscCurvedEdgeIsAntialiased() throws {
        let image = RateLimitIconRenderer().renderIcon(
            weekRemainingPercent: 0,
            weeklyResetAt: Date(timeIntervalSince1970: 7 * 24 * 60 * 60),
            now: Date(timeIntervalSince1970: 0),
            size: 64,
            drawNeedle: false
        )

        let color = try image.pixelColor(x: 54, y: 9)

        XCTAssertGreaterThan(color.alphaComponent, 0.1)
        XCTAssertLessThan(color.alphaComponent, 0.95)
    }

    func testNeedleProducesRedPixelsAtHalfwayThroughWeeklyWindow() throws {
        let image = RateLimitIconRenderer().renderIcon(
            weekRemainingPercent: 100,
            weeklyResetAt: Date(timeIntervalSince1970: 7 * 24 * 60 * 60),
            now: Date(timeIntervalSince1970: 3.5 * 24 * 60 * 60),
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
            let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil),
            let providerData = cgImage.dataProvider?.data,
            let bytes = CFDataGetBytePtr(providerData)
        else {
            XCTFail("Could not read image pixel")
            return .clear
        }
        let offset = y * cgImage.bytesPerRow + x * 4
        return NSColor(
            srgbRed: CGFloat(bytes[offset]) / 255,
            green: CGFloat(bytes[offset + 1]) / 255,
            blue: CGFloat(bytes[offset + 2]) / 255,
            alpha: CGFloat(bytes[offset + 3]) / 255
        )
    }
}
