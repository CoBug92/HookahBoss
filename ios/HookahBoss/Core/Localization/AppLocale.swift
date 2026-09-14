import Foundation

enum AppLocale: String, Sendable {
    case ru
    case en

    static var current: AppLocale {
        Locale.current.language.languageCode?.identifier == "en" ? .en : .ru
    }

    static var currentApp: AppLocale { current }
}
