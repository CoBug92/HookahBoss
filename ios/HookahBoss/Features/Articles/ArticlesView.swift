import SwiftUI

struct ArticlesView: View {

    // MARK: - Properties

    @Namespace private var articleTransitionNamespace
    @StateObject private var model: ArticlesViewModel
    private let makeDetailModel: (ArticleDTO) -> ArticleDetailViewModel

    // MARK: - Computed properties

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ArticlesSkeletonView()
        case .content:
            loadedContent
        case .cached:
            ArticlesCachedContentView(
                articles: model.articles,
                isBookmarked: model.isBookmarked,
                toggleBookmark: model.toggleBookmark,
                onRetry: retry
            )
        case .empty:
            ArticlesStatusView(
                icon: AppSymbol.article,
                title: L10n.Articles.Empty.title,
                message: L10n.Articles.Empty.message,
                actionTitle: L10n.Common.refresh,
                action: retry
            )
        case .failure:
            ArticlesStatusView(
                icon: AppSymbol.retryUnavailable,
                title: L10n.Articles.Error.title,
                message: L10n.Articles.Error.message,
                actionTitle: L10n.Common.retry,
                action: retry
            )
        }
    }

    private var loadedContent: some View {
        ArticlesLoadedContentView(
            articles: model.articles,
            isBookmarked: model.isBookmarked,
            toggleBookmark: model.toggleBookmark
        )
    }

    // MARK: - Init

    init(
        model: @autoclosure @escaping () -> ArticlesViewModel,
        makeDetailModel: @escaping (ArticleDTO) -> ArticleDetailViewModel
    ) {
        _model = StateObject(wrappedValue: model())
        self.makeDetailModel = makeDetailModel
    }

    // MARK: - Layout

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding(.horizontal, Margin.x8)
                    .padding(.top, Margin.x2)
                    .padding(.bottom, Margin.x10)
            }
            .scrollIndicators(.hidden)
            .refreshable { await model.refresh() }
            .task { await model.appear() }
            .navigationTitle(L10n.Tab.articles)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: ArticleDestination.bookmarks) {
                        Image(systemName: AppSymbol.bookmark)
                            .foregroundStyle(AppTheme.gold)
                    }
                    .accessibilityLabel(Text(L10n.Articles.bookmarks))
                }
            }
            .navigationDestination(for: ArticleCategory.self) { category in
                ArticleListView(content: .category(category), model: model)
            }
            .navigationDestination(for: ArticleDestination.self) { _ in
                ArticleListView(content: .bookmarks, model: model)
            }
            .navigationDestination(for: ArticleDTO.self) { article in
                ArticleDetailView(
                    article: article,
                    model: makeDetailModel(article)
                )
            }
            .onAppear { model.syncLibraryState() }
            .alert(
                L10n.Content.Error.title,
                isPresented: Binding(
                    get: { model.errorMessage != nil },
                    set: { if !$0 { model.clearError() } }
                )
            ) {
                Button(L10n.Common.close) { model.clearError() }
            } message: {
                Text(model.errorMessage ?? TechnicalString.empty)
            }
            .background(AppTheme.background)
            .accessibilityIdentifier(AccessibilityID.articles)
        }
        .environment(\.articleTransitionNamespace, articleTransitionNamespace)
    }

    // MARK: - Private methods

    private func retry() {
        Task {
            await model.refresh()
        }
    }
}

@MainActor
private func articlesPreview(content: PreviewPublicCatalogService) -> some View {
    let library = PreviewAuthLibraryService()

    return ArticlesView(
        model: ArticlesViewModel(
            content: content,
            library: library
        ),
        makeDetailModel: { article in
            ArticleDetailViewModel(
                article: article,
                content: content,
                library: library
            )
        }
    )
}

// MARK: - Preview

#Preview("Loading") {
    articlesPreview(
        content: PreviewPublicCatalogService(
            articles: ArticlesPreviewData.articles,
            article: ArticlesPreviewData.detail,
            catalogDelay: .seconds(60)
        )
    )
}

#Preview("Content") {
    articlesPreview(
        content: PreviewPublicCatalogService(
            articles: ArticlesPreviewData.articles,
            article: ArticlesPreviewData.detail
        )
    )
}

#Preview("Cached") {
    articlesPreview(
        content: PreviewPublicCatalogService(
            articles: ArticlesPreviewData.articles,
            article: ArticlesPreviewData.detail,
            freshness: .cached
        )
    )
}

#Preview("Empty") {
    articlesPreview(content: PreviewPublicCatalogService())
}

#Preview("Error") {
    articlesPreview(
        content: PreviewPublicCatalogService(catalogFails: true)
    )
}
