import Foundation

@MainActor
final class ArticleDetailViewModel: ObservableObject {

    // MARK: - Observable properties

    @Published private(set) var state = ArticleDetailViewState.loading
    @Published private(set) var errorMessage: String?

    // MARK: - Properties

    private let article: ArticleDTO
    private let content: any PublicCatalogServing
    private let library: any AuthLibraryServing

    // MARK: - Computed properties

    var isBookmarked: Bool {
        library.bookmarkedArticleSlugs.contains(article.slug)
    }

    // MARK: - Init

    init(
        article: ArticleDTO,
        content: any PublicCatalogServing,
        library: any AuthLibraryServing
    ) {
        self.article = article
        self.content = content
        self.library = library
    }

    // MARK: - Public methods

    func appear() async {
        guard case .loading = state else { return }
        await load()
    }

    func retry() async {
        state = .loading
        await load()
    }

    func clearError() {
        errorMessage = nil
        library.libraryError = nil
    }

    func toggleBookmark() {
        library.authorize(.bookmark) { [weak self] in
            Task { await self?.performBookmarkToggle() }
        }
    }

    // MARK: - Private methods

    private func load() async {
        do {
            let detail = try await content.articleDetail(
                article.slug,
                locale: .currentApp
            )
            state = .content(detail)
        } catch {
            state = .failure
        }
    }

    private func performBookmarkToggle() async {
        await library.setArticleBookmark(!isBookmarked, slug: article.slug)
        errorMessage = library.libraryError
        objectWillChange.send()
    }
}
