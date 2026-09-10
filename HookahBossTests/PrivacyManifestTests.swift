import XCTest

final class PrivacyManifestTests: XCTestCase {
    func testManifestDeclaresOnlyExpectedCollectionAndRequiredReasonAPIs() throws {
        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("HookahBoss/PrivacyInfo.xcprivacy")
        let data = try Data(contentsOf: sourceURL)
        let manifest = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )

        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)
        let collected = try XCTUnwrap(manifest["NSPrivacyCollectedDataTypes"] as? [[String: Any]])
        XCTAssertEqual(Set(collected.compactMap { $0["NSPrivacyCollectedDataType"] as? String }), [
            "NSPrivacyCollectedDataTypeUserID",
            "NSPrivacyCollectedDataTypeOtherUserContent",
            "NSPrivacyCollectedDataTypeProductInteraction"
        ])
        XCTAssertTrue(collected.allSatisfy { ($0["NSPrivacyCollectedDataTypeLinked"] as? Bool) == true })
        XCTAssertTrue(collected.allSatisfy { ($0["NSPrivacyCollectedDataTypeTracking"] as? Bool) == false })

        let accessed = try XCTUnwrap(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        XCTAssertEqual(accessed.count, 1)
        XCTAssertEqual(accessed[0]["NSPrivacyAccessedAPIType"] as? String, "NSPrivacyAccessedAPICategoryUserDefaults")
        XCTAssertEqual(accessed[0]["NSPrivacyAccessedAPITypeReasons"] as? [String], ["CA92.1"])
    }

    func testManifestIsCopiedIntoApplicationBundle() {
        XCTAssertNotNil(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
    }
}
