import SwiftUI
import UIKit

enum AppTheme {
    static let gold = Color(.Brand.gold)
    static let cream = Color(.Surface.cream)
    static let graphite = Color(.Surface.graphite)
    static let cardDark = Color(.Surface.cardDark)

    static let backgroundUIColor = UIColor(resource: .Surface.background)
    static let cardUIColor = UIColor(resource: .Surface.card)
    static let elevatedUIColor = UIColor(resource: .Surface.elevated)
    static let goldUIColor = UIColor(resource: .Brand.gold)

    static let background = Color(.Surface.background)
    static let card = Color(.Surface.card)
    static let elevated = Color(.Surface.elevated)

    static func resolved(_ color: UIColor, style: UIUserInterfaceStyle) -> UIColor {
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    }

    static func ratingColor(for rating: Int?) -> Color {
        switch rating {
        case 1: Color(.Rating.one)
        case 2: Color(.Rating.two)
        case 3: Color(.Rating.three)
        case 4: Color(.Rating.four)
        case 5: Color(.Rating.five)
        default: Color(.Rating.default)
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
            .shadow(
                color: .black.opacity(0.045),
                radius: 14,
                y: Margin.x3
            )
    }
}

struct AppSectionHeader: View {
    let title: String
    var action: String?
    var body: some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: Margin.x4
        ) {
            Text(title).font(.title3.weight(.bold)); Spacer()
            if let action { Text(action).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.gold) }
        }
    }
}

struct AppEmptyState: View {
    let icon: String; let title: String; let message: String
    var body: some View {
        VStack(spacing: Margin.x6) {
            Image(systemName: icon).font(.system(size: 28, weight: .light)).foregroundStyle(AppTheme.gold).frame(width: 58, height: 58)
                .background(AppTheme.gold.opacity(0.12), in: Circle())
            Text(title).font(.title3.bold()); Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(Margin.x7).frame(maxWidth: .infinity).appCard(cornerRadius: 24)
    }
}
