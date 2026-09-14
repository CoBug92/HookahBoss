import Foundation

/// Минимальный key-value контракт, изолирующий хранилища от `UserDefaults`.
protocol KeyValueStoring: AnyObject {
    /// Возвращает данные по ключу.
    func data(forKey defaultName: String) -> Data?

    /// Сохраняет значение по ключу.
    func set(_ value: Any?, forKey defaultName: String)
}
