import Foundation

@MainActor
final class ArticlesViewModel: ObservableObject {
    @Published private(set) var articles: [ArticleDTO] = []
    @Published private(set) var isLoading = false
    private let content: any PublicCatalogServing
    private let library: any AuthLibraryServing
    init(content: any PublicCatalogServing, library: any AuthLibraryServing) { self.content = content; self.library = library }
    func appear() async { await refresh(force: false) }
    func refresh(force: Bool = true) async { isLoading = true; defer { isLoading = false }; articles = await content.catalog(locale: .currentApp, force: force).articles }
    func articles(in category: ArticleCategory) -> [ArticleDTO] { articles.filter { $0.appCategory == category } }
    var bookmarks: [ArticleDTO] { articles.filter { library.bookmarkedArticleSlugs.contains($0.slug) } }
    func isBookmarked(_ article: ArticleDTO) -> Bool { library.bookmarkedArticleSlugs.contains(article.slug) }
    func toggleBookmark(_ article: ArticleDTO) { library.authorize(.bookmark) { [weak self] in Task { await self?.performBookmark(article) } } }
    private func performBookmark(_ article: ArticleDTO) async { await library.setArticleBookmark(!isBookmarked(article), slug: article.slug); objectWillChange.send() }
}

@MainActor
final class ArticleDetailViewModel: ObservableObject {
    @Published private(set) var detail: ArticleDetailDTO?
    @Published private(set) var failed = false
    private let article: ArticleDTO
    private let content: any PublicCatalogServing
    private let library: any AuthLibraryServing
    init(article: ArticleDTO, content: any PublicCatalogServing, library: any AuthLibraryServing) { self.article = article; self.content = content; self.library = library }
    var isBookmarked: Bool { library.bookmarkedArticleSlugs.contains(article.slug) }
    func appear() async { do { detail = try await content.articleDetail(article.slug, locale: .currentApp); failed = false } catch { failed = true } }
    func toggleBookmark() { library.authorize(.bookmark) { [weak self] in Task { guard let self else { return }; await self.library.setArticleBookmark(!self.isBookmarked, slug: self.article.slug); self.objectWillChange.send() } } }
}
