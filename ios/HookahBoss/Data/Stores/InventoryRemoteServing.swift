import Foundation

/// Выполняет удалённые операции с инвентарём аккаунта.
@MainActor
protocol InventoryRemoteServing {
    /// Загружает актуальный инвентарь.
    func inventory() async throws -> [InventoryItemDTO]
    /// Создаёт или обновляет уровень продукта.
    func upsertInventory(_ input: InventoryUpsert) async throws -> InventoryItemDTO
    /// Создаёт пользовательский продукт.
    func createPrivateProduct(_ input: PrivateProductWrite) async throws -> PrivateProductDTO
    /// Удаляет пользовательский продукт.
    func deletePrivateProduct(id: UUID) async throws
}
