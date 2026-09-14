extension ArticleDTO {
    var appCategory: ArticleCategory {
        switch category {
        case "fundamentals": .basics
        case "bowls_heat": .heat
        default: ArticleCategory(rawValue: category) ?? .basics
        }
    }
}
