import Foundation

/// Boundary for localization keys selected from server-driven metadata.
/// Static application copy must use generated `L10n` symbols directly.
enum AppLocalization {
    static func dynamic(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }
}
