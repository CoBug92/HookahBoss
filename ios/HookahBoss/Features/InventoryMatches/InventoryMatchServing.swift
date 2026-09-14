/// Ищет миксы, совместимые с текущим инвентарём.
@MainActor
protocol InventoryMatchServing: AnyObject {
    /// Возвращает результаты сопоставления для локали.
    func matches(locale: AppLocale) async throws -> [InventoryMatchDTO]
}
