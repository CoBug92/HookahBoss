import SwiftUI

struct ArticleDetailView: View {

    // MARK: - Properties

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var model: ArticleDetailViewModel
    @State private var isPresentationVisible = false

    let article: ArticleDTO

    // MARK: - Init

    init(
        article: ArticleDTO,
        model: @autoclosure @escaping () -> ArticleDetailViewModel
    ) {
        self.article = article
        _model = StateObject(wrappedValue: model())
    }

    // MARK: - Layout

    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                ArticleDetailHeroView(
                    article: article,
                    isAnimated: isPresentationVisible && !reduceMotion
                )
                content
            }
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                bookmarkButton
            }
        }
        .task { await model.appear() }
        .task { await presentContent() }
        .accessibilityIdentifier("screen.articleDetail")
        .articleNavigationTransition(sourceID: article.id)
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
    }

    // MARK: - Computed properties

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ArticleDetailSkeletonView()
                .offset(y: -Margin.x(12))
        case .content(let detail):
            ArticleDetailContentView(
                detail: detail,
                isPresented: isPresentationVisible
            )
        case .failure:
            ArticleDetailErrorView(retry: retry)
        }
    }

    private var bookmarkButton: some View {
        Button {
            model.toggleBookmark()
        } label: {
            Image(
                systemName: model.isBookmarked
                    ? AppSymbol.bookmarkFilled
                    : AppSymbol.bookmark
            )
        }
        .accessibilityLabel(
            Text(
                model.isBookmarked
                    ? L10n.Articles.Bookmark.remove
                    : L10n.Articles.Bookmark.add
            )
        )
        .accessibilityValue(
            Text(
                model.isBookmarked
                    ? L10n.Accessibility.selected
                    : L10n.Accessibility.notSelected
            )
        )
    }

    // MARK: - Private methods

    private func retry() {
        Task { await model.retry() }
    }

    private func presentContent() async {
        guard !reduceMotion else {
            isPresentationVisible = true
            return
        }

        try? await Task.sleep(for: .navigationTransitionDelay)
        guard !Task.isCancelled else { return }
        isPresentationVisible = true
    }
}

private extension Duration {
    static let navigationTransitionDelay = Duration.milliseconds(250)
}

// MARK: - Preview

#Preview("Content") {
    let content = PreviewPublicCatalogService(article: ArticleDetailPreviewData.detail)
    let library = PreviewAuthLibraryService()

    NavigationStack {
        ArticleDetailView(
            article: ArticleDetailPreviewData.article,
            model: ArticleDetailViewModel(
                article: ArticleDetailPreviewData.article,
                content: content,
                library: library
            )
        )
    }
}

#Preview("Loading") {
    let content = PreviewPublicCatalogService(
        article: ArticleDetailPreviewData.detail,
        detailDelay: .seconds(60)
    )
    let library = PreviewAuthLibraryService()

    NavigationStack {
        ArticleDetailView(
            article: ArticleDetailPreviewData.article,
            model: ArticleDetailViewModel(
                article: ArticleDetailPreviewData.article,
                content: content,
                library: library
            )
        )
    }
}

#Preview("Error") {
    let content = PreviewPublicCatalogService(detailFails: true)
    let library = PreviewAuthLibraryService()

    NavigationStack {
        ArticleDetailView(
            article: ArticleDetailPreviewData.article,
            model: ArticleDetailViewModel(
                article: ArticleDetailPreviewData.article,
                content: content,
                library: library
            )
        )
    }
}
