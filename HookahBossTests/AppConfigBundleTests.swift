import XCTest
@testable import HookahBoss

final class AppConfigBundleTests: XCTestCase {
    func testBuiltDebugAppContainsUsableLocalAPIBaseURL() throws {
        let value = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String)
        XCTAssertEqual(value, "http://127.0.0.1:3010")
        XCTAssertEqual(try AppConfig.load(bundle: .main, isDebug: true).apiBaseURL.absoluteString, value)
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
