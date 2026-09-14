import Foundation

/// Предоставляет асинхронный cache для публичного каталога.
protocol PublicCache: Sendable {
    /// Возвращает сохранённые данные по ключу или `nil`, если записи нет либо она недоступна.
    func read(_ key: String) async -> Data?
    /// Сохраняет данные по ключу; сбой cache не должен блокировать сетевой результат.
    func write(_ data: Data, key: String) async
}
