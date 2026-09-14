/// Предоставляет административные CRUD-операции над поддерживаемыми ресурсами.
@MainActor
protocol AdminServing {
    /// Загружает записи ресурса.
    func adminList(_ resource: AdminResource) async throws -> [AdminRecordDTO]
    /// Создаёт запись и возвращает серверное представление.
    func adminCreate(_ resource: AdminResource, body: [String: JSONValue]) async throws -> AdminRecordDTO
    /// Обновляет запись и возвращает серверное представление.
    func adminUpdate(_ resource: AdminResource, id: String, body: [String: JSONValue]) async throws -> AdminRecordDTO
    /// Удаляет запись, опционально передавая служебное тело запроса.
    func adminDelete(_ resource: AdminResource, id: String, body: [String: JSONValue]?) async throws
}
