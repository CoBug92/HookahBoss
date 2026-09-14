import SwiftUI

struct ArticleEditorialCard: View {
    let article: ArticleDTO
    let height: CGFloat
    let prominent: Bool

    var body: some View {
        NavigationLink(value: article) {
            GeometryReader { proxy in
                ZStack(alignment: .bottomLeading) {
                    ArticleSpecificArtwork(article: article)
                        .frame(
                            width: proxy.size.width,
                            height: proxy.size.height
                        )
                        .articleTransitionSource(id: article.id)

                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: .gradientStart),
                            .init(
                                color: .black.opacity(.middleOpacity),
                                location: .gradientMiddle
                            ),
                            .init(color: .black.opacity(.endOpacity), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    metadata
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .clipShape(
            RoundedRectangle(
                cornerRadius: prominent ? .prominentCornerRadius : .cornerRadius,
                style: .continuous
            )
        )
        .accessibilityIdentifier("article.row.\(article.slug)")
    }

    private var metadata: some View {
        VStack(
            alignment: .leading,
            spacing: prominent ? Margin.x4 : Margin.x2
        ) {
            ArticleCategoryBadge(
                title: article.appCategory.title,
                onArtwork: true
            )

            Text(L10n.Articles.minutesLld(article.readingMinutes).uppercased())
                .font(
                    .system(
                        size: prominent ? .prominentMetadataSize : .metadataSize,
                        weight: .semibold
                    )
                )
                .tracking(.metadataTracking)
                .foregroundStyle(.white.opacity(.metadataOpacity))
                .lineLimit(1)

            Text(article.title)
                .font(
                    .system(
                        size: prominent ? .prominentTitleSize : .titleSize,
                        weight: .bold
                    )
                )
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(prominent ? 3 : 2)
                .minimumScaleFactor(.titleMinimumScale)
        }
        .padding(prominent ? Margin.x8 : Margin.x6)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .bottomLeading
        )
    }
}

// MARK: - Constants

private extension CGFloat {
    static let gradientStart: CGFloat = 0.16
    static let gradientMiddle: CGFloat = 0.52
    static let prominentMetadataSize: CGFloat = 9
    static let metadataSize: CGFloat = 8
    static let metadataTracking: CGFloat = 0.6
    static let prominentTitleSize: CGFloat = 17
    static let titleSize: CGFloat = 13
    static let titleMinimumScale: CGFloat = 0.86
    static let prominentCornerRadius: CGFloat = 21
    static let cornerRadius: CGFloat = 18
}

private extension Double {
    static let middleOpacity: Double = 0.45
    static let endOpacity: Double = 0.92
    static let metadataOpacity: Double = 0.78
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    NavigationStack {
        ArticleEditorialCard(
            article: ArticlesPreviewData.featured,
            height: 258,
            prominent: true
        )
        .frame(width: 202)
        .padding(Margin.x5)
    }
}
