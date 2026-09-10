import XCTest
@testable import HookahBoss

final class AppConfigBundleTests: XCTestCase {
    func testBuiltDebugAppContainsUsableAPIBaseURL() throws {
        let value = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String)
        let config = try AppConfig.load(bundle: .main, isDebug: true)
        XCTAssertEqual(config.apiBaseURL.absoluteString, value)
        XCTAssertNotNil(config.apiBaseURL.host)
        XCTAssertTrue(["http", "https"].contains(config.apiBaseURL.scheme?.lowercased()))
    }

    func testReleaseConfigurationRequiresExplicitHTTPSURL() {
        XCTAssertThrowsError(try AppConfig.validate(raw: nil, isDebug: false)) {
            XCTAssertEqual($0 as? AppConfigError, .missingAPIBaseURL)
        }
        XCTAssertThrowsError(try AppConfig.validate(raw: "http://api.example.com", isDebug: false)) {
            XCTAssertEqual($0 as? AppConfigError, .insecureReleaseURL)
        }
        XCTAssertNoThrow(try AppConfig.validate(raw: "https://api.example.com", isDebug: false))
    }
}
