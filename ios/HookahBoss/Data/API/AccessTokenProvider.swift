/// Предоставляет действующий access token для авторизованных API-запросов.
protocol AccessTokenProvider: Sendable {
    /// Возвращает токен, при необходимости обновляя отклонённый сервером токен.
    func accessToken(afterRejectedToken: String?) async throws -> String
}
