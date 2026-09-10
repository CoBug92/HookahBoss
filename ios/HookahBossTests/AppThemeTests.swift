import XCTest
import UIKit
@testable import HookahBoss

final class AppThemeTests: XCTestCase {
    func testSemanticSurfacesResolveDifferentlyForLightAndDarkAppearances() {
        let lightBackground = AppTheme.resolved(AppTheme.backgroundUIColor, style: .light)
        let darkBackground = AppTheme.resolved(AppTheme.backgroundUIColor, style: .dark)
        let lightCard = AppTheme.resolved(AppTheme.cardUIColor, style: .light)
        let darkCard = AppTheme.resolved(AppTheme.cardUIColor, style: .dark)

        XCTAssertGreaterThan(luminance(lightBackground), 0.75)
        XCTAssertLessThan(luminance(darkBackground), 0.03)
        XCTAssertGreaterThan(luminance(lightCard), luminance(lightBackground))
        XCTAssertGreaterThan(luminance(darkCard), luminance(darkBackground))
    }

    func testGoldRetainsReadableContrastAgainstEachBackground() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let background = AppTheme.resolved(AppTheme.backgroundUIColor, style: style)
            let gold = AppTheme.resolved(AppTheme.goldUIColor, style: style)
            XCTAssertGreaterThan(contrastRatio(background, gold), 3.0)
        }
    }

    private func contrastRatio(_ lhs: UIColor, _ rhs: UIColor) -> CGFloat {
        let lighter = max(luminance(lhs), luminance(rhs))
        let darker = min(luminance(lhs), luminance(rhs))
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func luminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        func linear(_ value: CGFloat) -> CGFloat {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}
