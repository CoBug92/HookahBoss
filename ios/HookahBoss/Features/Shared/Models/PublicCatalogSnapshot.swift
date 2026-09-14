struct PublicCatalogSnapshot: Sendable {
    let mixes: [MixPreview]
    let articles: [ArticleDTO]
    let freshness: PublicCatalogFreshness
}
