import SwiftUI

struct PersonalMixArtwork: View {

    // MARK: - Properties

    let mix: PersonalMixRecord

    private var profiles: [String] {
        Array(Set(mix.components.flatMap { $0.flavorProfiles ?? [] })).sorted()
    }

    private var colors: [Color] {
        let mapped = profiles.prefix(3).map(Self.color)
        return mapped.isEmpty ? [AppTheme.gold, .orange] : mapped
    }

    // MARK: - Layout

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(.white.opacity(.lightDecorationOpacity))
                .frame(width: .lightDecorationSize)
                .offset(x: Margin.x9, y: -Margin.x8)
            Circle()
                .fill(.black.opacity(.darkDecorationOpacity))
                .frame(width: .darkDecorationSize)
                .offset(x: -Margin.x10, y: Margin.x(11))
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: .cornerRadius,
                style: .continuous
            )
        )
        .accessibilityHidden(true)
    }

    // MARK: - Private methods

    private static func color(_ profile: String) -> Color {
        switch profile {
        case "berry": .pink
        case "fruit": .orange
        case "citrus": .yellow
        case "dessert": .brown
        case "beverage": .cyan
        case "herbal": .green
        case "spicy": .red
        case "fresh": .cyan
        default: AppTheme.gold
        }
    }
}

// MARK: - Constants

private extension CGFloat {
    static let lightDecorationSize: CGFloat = 42
    static let darkDecorationSize: CGFloat = 48
    static let cornerRadius: CGFloat = 16
    static let previewSize: CGFloat = 160
}

private extension Double {
    static let lightDecorationOpacity = 0.22
    static let darkDecorationOpacity = 0.16
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    PersonalMixArtwork(mix: PersonalMixPreviewData.tropical)
        .frame(width: .previewSize, height: .previewSize)
        .padding(Margin.x8)
}
