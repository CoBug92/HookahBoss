import Foundation

@MainActor
final class PreviewPublicCatalogService: PublicCatalogServing, MixContentServing {
    private let snapshot: PublicCatalogSnapshot
    private let article: ArticleDetailDTO?
    private let catalogDelay: Duration?
    private let catalogFails: Bool
    private let detailDelay: Duration?
    private let detailFails: Bool

    init(
        mixes: [MixPreview] = [],
        articles: [ArticleDTO] = [],
        article: ArticleDetailDTO? = nil,
        freshness: PublicCatalogFreshness = .fresh,
        catalogDelay: Duration? = nil,
        catalogFails: Bool = false,
        detailDelay: Duration? = nil,
        detailFails: Bool = false
    ) {
        snapshot = PublicCatalogSnapshot(
            mixes: mixes,
            articles: articles,
            freshness: freshness
        )
        self.article = article
        self.catalogDelay = catalogDelay
        self.catalogFails = catalogFails
        self.detailDelay = detailDelay
        self.detailFails = detailFails
    }

    func catalog(locale: AppLocale, force: Bool) async throws -> PublicCatalogSnapshot {
        if let catalogDelay {
            try? await Task.sleep(for: catalogDelay)
        }
        if catalogFails {
            throw PreviewServiceError.unavailable
        }
        return snapshot
    }

    func articleDetail(_ id: String, locale: AppLocale) async throws -> ArticleDetailDTO {
        if let detailDelay {
            try? await Task.sleep(for: detailDelay)
        }
        if detailFails {
            throw PreviewServiceError.unavailable
        }
        guard let article else { throw PreviewServiceError.unavailable }
        return article
    }

    func cachedMixDetail(_ id: UUID, locale: AppLocale) async -> MixPreview? {
        snapshot.mixes.first { $0.id == id }
    }

    func mixDetail(_ id: UUID, locale: AppLocale) async throws -> MixPreview {
        guard let mix = snapshot.mixes.first(where: { $0.id == id }) else {
            throw PreviewServiceError.unavailable
        }
        return mix
    }
}
