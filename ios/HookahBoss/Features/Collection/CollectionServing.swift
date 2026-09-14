import Foundation

/// Координирует экран коллекции через presentation-friendly снимки и intent-методы.
@MainActor
protocol CollectionServing: AnyObject {
    /// Возвращает текущее состояние коллекции.
    func snapshot(locale: AppLocale) async -> CollectionSnapshot
    /// Запрашивает доступ к защищённому разделу.
    func requestAccess(_ action: ProtectedAction, resume: @escaping () -> Void)
    /// Изменяет уровень продукта в инвентаре.
    func setInventoryLevel(_ level: InventoryLevel, itemID: String)
    /// Добавляет каталожный продукт в инвентарь.
    func addInventoryProduct(_ product: TobaccoProductDTO)
    /// Создаёт личный продукт и сообщает об успехе.
    func createPrivateProduct(brand: String, line: String?, flavor: String, profiles: [String]) async -> Bool
    /// Удаляет личный продукт.
    func deletePrivateProduct(_ item: InventoryItem)
    /// Завершает пользовательскую сессию.
    func logout() async
    /// Удаляет аккаунт и возвращает признак недоступности provider revocation.
    func deleteAccount() async throws -> Bool
}
