import Foundation

/// Предоставляет экрану микса локальные и удалённые детали без раскрытия инфраструктуры.
@MainActor
protocol MixContentServing: AnyObject {
    /// Возвращает закэшированные детали, если они доступны.
    func cachedMixDetail(_ id: UUID, locale: AppLocale) async -> MixPreview?

    /// Загружает актуальные детали микса или выбрасывает ошибку источника.
    func mixDetail(_ id: UUID, locale: AppLocale) async throws -> MixPreview
}
