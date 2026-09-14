import SwiftUI

struct ArticleRow: View {
    let article: ArticleDTO
    let bookmarked: Bool
    let toggle: () -> Void

    var body: some View {
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

                VStack(
                    alignment: .leading,
                    spacing: Margin.x3
                ) {
                    ArticleCategoryBadge(
                        title: article.appCategory.title,
                        onArtwork: false
                    )
                    Text(article.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(L10n.Articles.minutesLld(article.readingMinutes))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: toggle) {
                    Image(
                        systemName: bookmarked
                            ? AppSymbol.bookmarkFilled
                            : AppSymbol.bookmark
                    )
                }
                .buttonStyle(.borderless)
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
        }
        .accessibilityIdentifier("article.row.\(article.slug)")
    }
}

// MARK: - Constants

private extension CGFloat {
    static let artworkSize: CGFloat = 68
    static let artworkCornerRadius: CGFloat = 13
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    NavigationStack {
        List {
            ArticleRow(
                article: ArticlesPreviewData.featured,
                bookmarked: false,
                toggle: {}
            )
        }
    }
}
