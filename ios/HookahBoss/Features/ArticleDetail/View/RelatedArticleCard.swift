import SwiftUI

struct RelatedArticleCard: View {
    let article: ArticleDTO

    var body: some View {
        HStack(spacing: Margin.x5) {
            ArticleSpecificArtwork(article: article)
                .frame(width: .artworkSize, height: .artworkSize)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: .artworkCornerRadius,
                        style: .continuous
                    )
                )
                .articleTransitionSource(id: article.id)

            VStack(alignment: .leading, spacing: Margin.x2) {
                ArticleCategoryBadge(
                    title: article.appCategory.title,
                    onArtwork: false
                )

                Text(article.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(L10n.Articles.minutesLld(article.readingMinutes))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: AppSymbol.disclosure)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(Margin.x5)
        .background(
            AppTheme.card,
            in: RoundedRectangle(cornerRadius: .cornerRadius)
        )
    }
}

// MARK: - Constants

private extension CGFloat {
    static let artworkSize: CGFloat = 64
    static let artworkCornerRadius: CGFloat = 12
    static let cornerRadius: CGFloat = 18
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    RelatedArticleCard(article: ArticleDetailPreviewData.related)
        .padding(Margin.x8)
        .background(AppTheme.background)
}
