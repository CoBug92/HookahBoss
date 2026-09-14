import Foundation

enum ArticleEditorialSelection {
    private static let preferredSlugs = [
        "hookah-components",
        "first-session-checklist",
        "building-a-mix",
    ]

    static func editorial(in articles: [ArticleDTO]) -> [ArticleDTO] {
        let preferred = preferredSlugs.compactMap { slug in
            articles.first { $0.slug == slug }
        }
        let preferredSet = Set(preferred.map(\.slug))
        return Array((preferred + articles.filter { !preferredSet.contains($0.slug) }).prefix(3))
    }

    static func recommendations(in articles: [ArticleDTO]) -> [ArticleDTO] {
        let editorialSet = Set(editorial(in: articles).map(\.slug))
        return Array(articles.filter { !editorialSet.contains($0.slug) }.prefix(3))
    }
}
