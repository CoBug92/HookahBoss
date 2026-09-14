/// Предоставляет данные конструктора и сохраняет персональный микс.
@MainActor
protocol CreateMixServing: AnyObject {
    /// Загружает доступные варианты компонентов.
    func loadOptions(locale: AppLocale) async throws -> CreateMixOptionSnapshot

    /// Сохраняет собранный микс.
    func save(_ mix: PersonalMixRecord) async throws
}
