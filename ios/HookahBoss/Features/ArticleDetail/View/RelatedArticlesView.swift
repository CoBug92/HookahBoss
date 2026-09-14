import SwiftUI

struct RelatedArticlesView: View {
    let articles: [ArticleDTO]

    var body: some View {
        VStack(alignment: .leading, spacing: Margin.x6) {
            Text(L10n.Articles.related)
                .font(.title2.bold())

            ForEach(articles) { article in
                NavigationLink(value: article) {
                    RelatedArticleCard(article: article)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("article.related.\(article.slug)")
            }
        }
        .accessibilityIdentifier("article.related")
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    NavigationStack {
        RelatedArticlesView(articles: [ArticleDetailPreviewData.related])
            .padding(Margin.x8)
            .background(AppTheme.background)
    }
}
