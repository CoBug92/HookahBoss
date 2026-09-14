import Foundation

/// Выполняет HTTP-запросы и возвращает необработанные данные вместе с HTTP-ответом.
protocol APITransport: Sendable {
    /// Отправляет запрос. Пробрасывает транспортные ошибки вызывающему коду.
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
