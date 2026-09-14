import SwiftUI

struct ArticleRecommendationRow: View {
    let article: ArticleDTO
    let bookmarked: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: Margin.x5) {
            NavigationLink(value: article) {
                HStack(spacing: Margin.x5) {
                    ArticleSpecificArtwork(article: article)
                        .frame(
                            width: .artworkSize,
                            height: .artworkSize
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: .artworkCornerRadius,
                                style: .continuous
                            )
                        )
                        .articleTransitionSource(id: article.id)

                    VStack(alignment: .leading, spacing: Margin.x3) {
                        ArticleCategoryBadge(
                            title: article.appCategory.title,
                            onArtwork: false
                        )

                        Text(L10n.Articles.minutesLld(article.readingMinutes))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(article.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: toggle) {
                Image(
                    systemName: bookmarked
                        ? AppSymbol.bookmarkFilled
                        : AppSymbol.bookmark
                )
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.gold)
                .frame(
                    width: .bookmarkButtonWidth,
                    height: .bookmarkButtonHeight
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text(
                    bookmarked
                        ? L10n.Articles.Bookmark.remove
                        : L10n.Articles.Bookmark.add
                )
            )
            .accessibilityValue(
                Text(
                    bookmarked
                        ? L10n.Accessibility.selected
                        : L10n.Accessibility.notSelected
                )
            )
        }
        .padding(Margin.x5)
        .appCard(cornerRadius: .cornerRadius)
        .accessibilityIdentifier("article.row.\(article.slug)")
    }
}

// MARK: - Constants

private extension CGFloat {
    static let artworkSize: CGFloat = 78
    static let artworkCornerRadius: CGFloat = 14
    static let bookmarkButtonWidth: CGFloat = 36
    static let bookmarkButtonHeight: CGFloat = 44
    static let cornerRadius: CGFloat = 18
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    NavigationStack {
        ArticleRecommendationRow(
            article: ArticlesPreviewData.featured,
            bookmarked: true,
            toggle: {}
        )
        .padding(Margin.x8)
        .background(AppTheme.background)
    }
}
