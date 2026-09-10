import Foundation

enum AppConfigError: Error, Equatable { case missingAPIBaseURL, insecureReleaseURL }

struct AppConfig: Sendable {
    let apiBaseURL: URL
    static func load(bundle: Bundle = .main, isDebug: Bool = _isDebugAssertConfiguration()) throws -> AppConfig {
        let raw = bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        return try validate(raw:raw,isDebug:isDebug)
    }
    static func validate(raw:String?,isDebug:Bool)throws->AppConfig {
        guard let raw, !raw.isEmpty, let url = URL(string: raw), url.host != nil else { throw AppConfigError.missingAPIBaseURL }
        if !isDebug && url.scheme?.lowercased() != "https" { throw AppConfigError.insecureReleaseURL }
        return AppConfig(apiBaseURL: url)
    }
}
