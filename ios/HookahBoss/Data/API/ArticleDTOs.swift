import Foundation

struct ArticleDTO: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let slug: String
    let title: String
    let summary: String
    let category: String
    let readingMinutes: Int
}

struct ArticleSectionDTO: Codable, Equatable, Hashable {
    let heading: String
    let body: String
}

struct ArticleDetailDTO: Codable, Equatable, Hashable {
    let id: UUID
    let slug: String
    let title: String
    let summary: String
    let sections: [ArticleSectionDTO]
    let category: String
    let readingMinutes: Int
    let related: [ArticleDTO]
}
