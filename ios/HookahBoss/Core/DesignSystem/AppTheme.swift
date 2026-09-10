import SwiftUI
import UIKit

enum AppTheme {
    static let gold = Color(uiColor: goldUIColor)
    static let cream = Color(red: 0.95, green: 0.92, blue: 0.87)
    static let graphite = Color(red: 0.09, green: 0.095, blue: 0.11)
    static let cardDark = Color(red: 0.14, green: 0.145, blue: 0.17)

    static let backgroundUIColor = dynamic(
        light: UIColor(red: 0.973, green: 0.945, blue: 0.902, alpha: 1),
        dark: UIColor(red: 0.090, green: 0.082, blue: 0.075, alpha: 1)
    )
    static let cardUIColor = dynamic(
        light: UIColor(red: 1.0, green: 0.980, blue: 0.941, alpha: 1),
        dark: UIColor(red: 0.145, green: 0.129, blue: 0.114, alpha: 1)
    )
    static let elevatedUIColor = dynamic(
        light: UIColor(red: 0.929, green: 0.878, blue: 0.816, alpha: 1),
        dark: UIColor(red: 0.188, green: 0.165, blue: 0.145, alpha: 1)
    )
    static let goldUIColor = dynamic(
        light: UIColor(red: 0.700, green: 0.480, blue: 0.200, alpha: 1),
        dark: UIColor(red: 0.831, green: 0.643, blue: 0.337, alpha: 1)
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

    func appCard(cornerRadius: CGFloat = 20) -> some View {
        background(AppTheme.card, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).stroke(.primary.opacity(0.07), lineWidth: 1) }
            .shadow(color: .black.opacity(0.045), radius: 14, y: 6)
    }
}

struct AppSectionHeader: View {
    let title: String
    var action: String?
    var body: some View { HStack(alignment: .firstTextBaseline) { Text(title).font(.title3.weight(.bold)); Spacer(); if let action { Text(action).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.gold) } } }
}

struct AppEmptyState: View {
    let icon: String; let title: String; let message: String
    var body: some View { VStack(spacing: 12) { Image(systemName: icon).font(.system(size: 28, weight: .light)).foregroundStyle(AppTheme.gold).frame(width: 58, height: 58).background(AppTheme.gold.opacity(0.12), in: Circle()); Text(title).font(.title3.bold()); Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center) }.padding(28).frame(maxWidth: .infinity).appCard(cornerRadius: 24) }
}
