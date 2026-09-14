/// Загружает публичные материалы, необходимые presentation-слою.
@MainActor
protocol PublicCatalogServing: AnyObject {
    /// Возвращает снимок каталога, при `force` игнорируя уже загруженное состояние.
    /// - Throws: Ошибку загрузки, если сервер и локальный кэш недоступны.
    func catalog(locale: AppLocale, force: Bool) async throws -> PublicCatalogSnapshot

    /// Загружает полное содержимое статьи.
    func articleDetail(_ id: String, locale: AppLocale) async throws -> ArticleDetailDTO
}
