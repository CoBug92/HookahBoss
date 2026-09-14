import SwiftUI

struct ArticlesLoadedContentView: View {
    let articles: [ArticleDTO]
    let isBookmarked: (ArticleDTO) -> Bool
    let toggleBookmark: (ArticleDTO) -> Void

    var body: some View {
        LazyVStack(
            alignment: .leading,
            spacing: Margin.x9
        ) {
            categories

            Text(L10n.Articles.editorChoice)
                .font(.title3.weight(.bold))

            ArticleEditorialGrid(
                articles: ArticleEditorialSelection.editorial(in: articles)
            )

            Text(L10n.Articles.continueReading)
                .font(.title3.weight(.bold))
                .padding(.top, Margin.x2)

            LazyVStack(spacing: Margin.x5) {
                ForEach(ArticleEditorialSelection.recommendations(in: articles)) { article in
                    ArticleRecommendationRow(
                        article: article,
                        bookmarked: isBookmarked(article),
                        toggle: { toggleBookmark(article) }
                    )
                }
            }
        }
    }

    private var categories: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Margin.x5) {
                ForEach(ArticleCategory.allCases) { category in
                    NavigationLink(value: category) {
                        CategoryCard(
                            category: category,
                            count: articles.filter { $0.appCategory == category }.count
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.trailing, Margin.x6, for: .scrollContent)
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    NavigationStack {
        ArticlesLoadedContentView(
            articles: ArticlesPreviewData.articles,
            isBookmarked: { _ in false },
            toggleBookmark: { _ in }
        )
        .padding(Margin.x8)
        .background(AppTheme.background)
    }
}
