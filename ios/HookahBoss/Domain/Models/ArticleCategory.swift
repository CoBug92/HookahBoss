enum ArticleCategory: String, CaseIterable, Identifiable, Codable {
    case basics, preparation, heat, care, safety

    var id: String { rawValue }
}
