import Foundation

/// Управляет пользовательской библиотекой и авторизацией защищённых действий.
@MainActor
protocol AuthLibraryServing: AnyObject {
    /// Показывает, доступна ли авторизованная библиотека.
    var isAuthenticated: Bool { get }
    /// Идентификаторы избранных миксов.
    var favoriteMixIDs: Set<UUID> { get }
    /// Пользовательские оценки по идентификатору микса.
    var ratings: [UUID: Int] { get }
    /// Slug сохранённых статей.
    var bookmarkedArticleSlugs: Set<String> { get }
    /// Последняя отображаемая ошибка синхронизации библиотеки.
    var libraryError: String? { get set }
    /// Запрашивает авторизацию и выполняет действие после успешного входа.
    func authorize(_ action: ProtectedAction, resume: @escaping () -> Void)
    /// Изменяет состояние избранного с синхронизацией.
    func setFavorite(_ enabled: Bool, mixId: UUID) async
    /// Сохраняет или удаляет пользовательскую оценку.
    func setRating(_ score: Int?, mixId: UUID) async
    /// Изменяет закладку статьи.
    func setArticleBookmark(_ enabled: Bool, slug: String) async
}
