import Foundation

@MainActor
final class ArticlesViewModel: ObservableObject {

    // MARK: - Observable properties

    @Published private(set) var articles: [ArticleDTO] = []
    @Published private(set) var state = ArticlesViewState.loading
    @Published private(set) var errorMessage: String?

    // MARK: - Properties

    private let content: any PublicCatalogServing
    private let library: any AuthLibraryServing

    // MARK: - Computed properties

    var bookmarks: [ArticleDTO] {
        articles.filter { library.bookmarkedArticleSlugs.contains($0.slug) }
    }

    // MARK: - Init

    init(
        content: any PublicCatalogServing,
        library: any AuthLibraryServing
    ) {
        self.content = content
        self.library = library
    }

    // MARK: - Public methods

    func appear() async {
        await refresh(force: false)
    }

    func refresh(force: Bool = true) async {
        if articles.isEmpty {
            state = .loading
        }

        do {
            let snapshot = try await content.catalog(
                locale: .currentApp,
                force: force
            )
            articles = snapshot.articles
            if articles.isEmpty {
                state = snapshot.freshness == .cached ? .failure : .empty
            } else {
                state = snapshot.freshness == .cached ? .cached : .content
            }
        } catch {
            if articles.isEmpty {
                state = .failure
            } else {
                state = .cached
            }
        }
    }

    func articles(in category: ArticleCategory) -> [ArticleDTO] {
        articles.filter { $0.appCategory == category }
    }

    func isBookmarked(_ article: ArticleDTO) -> Bool {
        library.bookmarkedArticleSlugs.contains(article.slug)
    }

    func syncLibraryState() {
        objectWillChange.send()
    }

    func clearError() {
        errorMessage = nil
        library.libraryError = nil
    }

    func toggleBookmark(_ article: ArticleDTO) {
        library.authorize(.bookmark) { [weak self] in
            Task { await self?.performBookmark(article) }
        }
    }

    // MARK: - Private methods

    private func performBookmark(_ article: ArticleDTO) async {
        await library.setArticleBookmark(!isBookmarked(article), slug: article.slug)
        errorMessage = library.libraryError
        objectWillChange.send()
    }
}
