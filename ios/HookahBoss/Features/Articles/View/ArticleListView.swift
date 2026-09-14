import SwiftUI

struct ArticleListView: View {
    enum Content {
        case category(ArticleCategory)
        case bookmarks
    }

    let content: Content
    @ObservedObject var model: ArticlesViewModel

    private var articles: [ArticleDTO] {
        switch content {
        case .category(let category):
            model.articles(in: category)
        case .bookmarks:
            model.bookmarks
        }
    }

    private var title: String {
        switch content {
        case .category(let category):
            category.title
        case .bookmarks:
            L10n.Articles.bookmarks
        }
    }

    private var emptyTitle: String {
        switch content {
        case .category:
            L10n.Articles.empty
        case .bookmarks:
            L10n.Articles.Bookmarks.empty
        }
    }

    var body: some View {
        Group {
            if articles.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: AppSymbol.bookmarkUnavailable
                )
            } else {
                List(articles) { article in
                    ArticleRow(
                        article: article,
                        bookmarked: model.isBookmarked(article),
                        toggle: { model.toggleBookmark(article) }
                    )
                    .listRowBackground(AppTheme.card)
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle(title)
        .appScreenBackground()
    }
}

// MARK: - Preview

#Preview {
    let service = PreviewPublicCatalogService(
        articles: ArticlesPreviewData.articles
    )
    let model = ArticlesViewModel(
        content: service,
        library: PreviewAuthLibraryService()
    )

    NavigationStack {
        ArticleListView(
            content: .category(.basics),
            model: model
        )
        .task { await model.appear() }
    }
}
