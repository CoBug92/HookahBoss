import Foundation

@MainActor
final class PreviewAuthLibraryService: AuthLibraryServing {
    var isAuthenticated = false
    var favoriteMixIDs: Set<UUID> = []
    var ratings: [UUID: Int] = [:]
    var bookmarkedArticleSlugs: Set<String> = []
    var libraryError: String?

    func authorize(_ action: ProtectedAction, resume: @escaping () -> Void) {
        resume()
    }

    func setFavorite(_ enabled: Bool, mixId: UUID) async {}
    func setRating(_ score: Int?, mixId: UUID) async {}
    func setArticleBookmark(_ enabled: Bool, slug: String) async {}
}
