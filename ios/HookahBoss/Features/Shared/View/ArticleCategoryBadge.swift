import SwiftUI

struct ArticleCategoryBadge: View {
    let title: String
    let onArtwork: Bool

    var body: some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(onArtwork ? .white : AppTheme.gold)
            .padding(.horizontal, Margin.x4)
            .padding(.vertical, Margin.x2)
            .background(
                onArtwork
                    ? Color.black.opacity(.artworkBackgroundOpacity)
                    : AppTheme.gold.opacity(.backgroundOpacity),
                in: Capsule()
            )
    }
}

// MARK: - Constants

private extension Double {
    static let artworkBackgroundOpacity: Double = 0.46
    static let backgroundOpacity: Double = 0.12
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    ArticleCategoryBadge(title: "Подготовка", onArtwork: false)
        .padding(Margin.x5)
        .background(AppTheme.background)
}
