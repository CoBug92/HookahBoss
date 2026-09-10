import SwiftUI
import UIKit

enum AppTheme {
    static let gold = Color(uiColor: goldUIColor)
    static let cream = Color(red: 0.95, green: 0.92, blue: 0.87)
    static let graphite = Color(red: 0.09, green: 0.095, blue: 0.11)
    static let cardDark = Color(red: 0.14, green: 0.145, blue: 0.17)

    static let backgroundUIColor = dynamic(
        light: UIColor(red: 0.969, green: 0.941, blue: 0.894, alpha: 1),
        dark: UIColor(red: 0.075, green: 0.078, blue: 0.086, alpha: 1)
    )
    static let cardUIColor = dynamic(
        light: UIColor(red: 1.0, green: 0.982, blue: 0.949, alpha: 1),
        dark: UIColor(red: 0.137, green: 0.141, blue: 0.153, alpha: 1)
    )
    static let elevatedUIColor = dynamic(
        light: UIColor(red: 0.945, green: 0.902, blue: 0.831, alpha: 1),
        dark: UIColor(red: 0.188, green: 0.192, blue: 0.204, alpha: 1)
    )
    static let goldUIColor = dynamic(
        light: UIColor(red: 0.65, green: 0.47, blue: 0.17, alpha: 1),
        dark: UIColor(red: 0.86, green: 0.70, blue: 0.36, alpha: 1)
    )

    static let background = Color(uiColor: backgroundUIColor)
    static let card = Color(uiColor: cardUIColor)
    static let elevated = Color(uiColor: elevatedUIColor)

    private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in traits.userInterfaceStyle == .dark ? dark : light }
    }

    static func resolved(_ color: UIColor, style: UIUserInterfaceStyle) -> UIColor {
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    }

    static func ratingColor(for rating: Int?) -> Color {
        switch rating {
        case 1: Color(red: 1.0, green: 0.40, blue: 0.36)
        case 2: Color(red: 1.0, green: 0.62, blue: 0.26)
        case 3: Color(red: 0.96, green: 0.81, blue: 0.27)
        case 4: Color(red: 0.57, green: 0.84, blue: 0.41)
        case 5: Color(red: 0.21, green: 0.83, blue: 0.55)
        default: Color(red: 0.73, green: 0.66, blue: 0.58)
        }
    }
}

extension View {
    func appScreenBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(AppTheme.background)
    }
}
