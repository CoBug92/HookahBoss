import Combine
import Foundation

@MainActor
final class AuthLibraryStore: ObservableObject {

    // MARK: - Observable properties

    @Published private(set) var favoriteMixIDs: Set<UUID> = []
    @Published private(set) var ratings: [UUID: Int] = [:]
    @Published private(set) var bookmarkedArticleSlugs: Set<String> = []
    @Published var syncError: String?

    // MARK: - Properties

    private var accountId: UUID?
    private var client: APIClient?

    // MARK: - Lifecycle

    func activate(accountId: UUID, client: APIClient?) {
        self.accountId = accountId
        self.client = client
        loadCache(accountId)

        Task {
            await reconcile()
        }
    }

    func deactivate() {
        accountId = nil
        client = nil
        favoriteMixIDs = []
        ratings = [:]
        bookmarkedArticleSlugs = []
        syncError = nil
    }

    // MARK: - Mutations

    func setFavorite(_ enabled: Bool, mixId: UUID) async {
        syncError = nil
        let previous = favoriteMixIDs
        if enabled {
            favoriteMixIDs.insert(mixId)
        } else {
            favoriteMixIDs.remove(mixId)
        }
        saveCache()

        do {
            if enabled {
                _ = try await client?.addFavorite(mixId: mixId)
            } else {
                try await client?.deleteFavorite(mixId: mixId)
            }
        } catch {
            if SyncFailurePolicy.disposition(for: error) == .queue {
                enqueue(.init(id: UUID(), kind: .favorite, mixId: mixId, value: enabled ? 1 : 0))
            } else {
                favoriteMixIDs = previous
            }
            syncError = L10n.Content.Error.network
            saveCache()
        }
    }

    func setRating(_ score: Int?, mixId: UUID) async {
        syncError = nil
        let previous = ratings
        ratings[mixId] = score
        saveCache()

        do {
            if let score {
                _ = try await client?.setRating(mixId: mixId, score: score)
            } else {
                try await client?.deleteRating(mixId: mixId)
            }
        } catch {
            if SyncFailurePolicy.disposition(for: error) == .queue {
                enqueue(.init(id: UUID(), kind: .rating, mixId: mixId, value: score))
            } else {
                ratings = previous
            }
            syncError = L10n.Content.Error.network
            saveCache()
        }
    }

    func setArticleBookmark(_ enabled: Bool, slug: String) async {
        syncError = nil
        let previous = bookmarkedArticleSlugs
        if enabled {
            bookmarkedArticleSlugs.insert(slug)
        } else {
            bookmarkedArticleSlugs.remove(slug)
        }
        saveCache()

        do {
            try await client?.setArticleBookmark(slug: slug, enabled: enabled)
        } catch {
            if error.isRetryableSyncFailure {
                enqueueBookmark(.init(slug: slug, enabled: enabled))
            } else {
                bookmarkedArticleSlugs = previous
            }
            syncError = L10n.Content.Error.network
            saveCache()
        }
    }

    // MARK: - Reconciliation

    private func reconcile() async {
        await replayOutbox()
        await replayBookmarkOutbox()
        guard let snapshot = try? await client?.library() else { return }

        let projection = LibraryProjection(
            favorites: Set(snapshot.favorites.map(\.mixId)),
            ratings: Dictionary(uniqueKeysWithValues: snapshot.ratings.map { ($0.mixId, $0.score) })
        )
        .overlaying(pendingMutations())
        favoriteMixIDs = projection.favorites
        ratings = projection.ratings
        bookmarkedArticleSlugs = Set(snapshot.articleBookmarks)

        for mutation in pendingBookmarks() {
            if mutation.enabled {
                bookmarkedArticleSlugs.insert(mutation.slug)
            } else {
                bookmarkedArticleSlugs.remove(mutation.slug)
            }
        }
        saveCache()
    }

    // MARK: - Persistence

    private func loadCache(_ accountId: UUID) {
        guard let data = UserDefaults.standard.data(forKey: AccountCache.key("library.v1", accountId: accountId)),
              let cached = try? JSONDecoder().decode(AuthLibraryCache.self, from: data) else {
            return
        }
        favoriteMixIDs = Set(cached.favorites)
        ratings = cached.ratings
        bookmarkedArticleSlugs = Set(cached.articleBookmarks ?? [])
    }

    private func saveCache() {
        guard let accountId,
              let data = try? JSONEncoder().encode(
                  AuthLibraryCache(
                      favorites: Array(favoriteMixIDs),
                      ratings: ratings,
                      articleBookmarks: Array(bookmarkedArticleSlugs)
                  )
              ) else {
            return
        }
        UserDefaults.standard.set(data, forKey: AccountCache.key("library.v1", accountId: accountId))
    }

    private func enqueue(_ mutation: LibraryMutation) {
        guard let accountId else { return }
        let key = AccountCache.key("library.outbox.v1", accountId: accountId)
        let queue = UserDefaults.standard.data(forKey: key)
            .flatMap { try? JSONDecoder().decode([LibraryMutation].self, from: $0) } ?? []
        let updated = OutboxQueue.upserting(mutation, in: queue) { $0.kind == $1.kind && $0.mixId == $1.mixId }
        UserDefaults.standard.set(try? JSONEncoder().encode(updated), forKey: key)
    }

    private func pendingMutations() -> [LibraryMutation] {
        guard let accountId else { return [] }
        return UserDefaults.standard.data(forKey: AccountCache.key("library.outbox.v1", accountId: accountId))
            .flatMap { try? JSONDecoder().decode([LibraryMutation].self, from: $0) } ?? []
    }

    private func bookmarkOutboxKey() -> String? {
        accountId.map { AccountCache.key("bookmark.outbox.v1", accountId: $0) }
    }

    private func pendingBookmarks() -> [BookmarkMutation] {
        guard let key = bookmarkOutboxKey() else { return [] }
        return UserDefaults.standard.data(forKey: key)
            .flatMap { try? JSONDecoder().decode([BookmarkMutation].self, from: $0) } ?? []
    }

    private func enqueueBookmark(_ mutation: BookmarkMutation) {
        guard let key = bookmarkOutboxKey() else { return }
        let queue = OutboxQueue.upserting(mutation, in: pendingBookmarks()) { $0.slug == $1.slug }
        UserDefaults.standard.set(try? JSONEncoder().encode(queue), forKey: key)
    }

    private func replayBookmarkOutbox() async {
        guard let client, let key = bookmarkOutboxKey() else { return }
        var queue = pendingBookmarks()
        for mutation in queue {
            do {
                try await client.setArticleBookmark(slug: mutation.slug, enabled: mutation.enabled)
                queue.removeAll { $0.slug == mutation.slug }
            } catch {
                if error.isRetryableSyncFailure {
                    break
                }
                queue.removeAll { $0.slug == mutation.slug }
            }
        }
        UserDefaults.standard.set(try? JSONEncoder().encode(queue), forKey: key)
    }

    private func replayOutbox() async {
        guard let accountId, let client else { return }
        let key = AccountCache.key("library.outbox.v1", accountId: accountId)
        guard var queue = UserDefaults.standard.data(forKey: key)
            .flatMap({ try? JSONDecoder().decode([LibraryMutation].self, from: $0) }) else {
            return
        }

        for mutation in queue {
            do {
                switch mutation.kind {
                case .favorite:
                    if mutation.value == 1 {
                        _ = try await client.addFavorite(mixId: mutation.mixId)
                    } else {
                        try await client.deleteFavorite(mixId: mutation.mixId)
                    }
                case .rating:
                    if let score = mutation.value {
                        _ = try await client.setRating(mixId: mutation.mixId, score: score)
                    } else {
                        try await client.deleteRating(mixId: mutation.mixId)
                    }
                }
                queue.removeAll { $0.id == mutation.id }
            } catch {
                if error.isRetryableSyncFailure {
                    break
                }
                queue.removeAll { $0.id == mutation.id }
            }
        }
        UserDefaults.standard.set(try? JSONEncoder().encode(queue), forKey: key)
    }
}

private struct AuthLibraryCache: Codable {
    let favorites: [UUID]
    let ratings: [UUID: Int]
    let articleBookmarks: [String]?
}
