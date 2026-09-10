import XCTest

final class ProductMetadataTests: XCTestCase {
    func testProjectUsesMixingBundleIdentifiers() throws {
        let iosRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let project = try String(
            contentsOf: iosRoot.appending(path: "scripts/xcodegen/Application.yml"),
            encoding: .utf8
        )

        XCTAssertTrue(project.contains("PRODUCT_BUNDLE_IDENTIFIER: ru.kostyuchenko.mixing\n"))
        XCTAssertTrue(project.contains("PRODUCT_BUNDLE_IDENTIFIER: ru.kostyuchenko.mixing.tests"))
        XCTAssertTrue(project.contains("PRODUCT_BUNDLE_IDENTIFIER: ru.kostyuchenko.mixing.uitests"))
    }

    func testDisplayNameIsLocalizedInRussianAndEnglish() throws {
        let iosRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let localizationRoot = iosRoot.appending(path: "HookahBoss/Resources/Localization")
        let english = try String(
            contentsOf: localizationRoot.appending(path: "en.lproj/InfoPlist.strings"),
            encoding: .utf8
        )
        let russian = try String(
            contentsOf: localizationRoot.appending(path: "ru.lproj/InfoPlist.strings"),
            encoding: .utf8
        )

        XCTAssertTrue(english.contains("\"CFBundleDisplayName\" = \"Mixing\";"))
        XCTAssertTrue(russian.contains("\"CFBundleDisplayName\" = \"Миксовка\";"))
    }

    func testInfoPlistUsesBuildSettingsForReleaseVersioning() throws {
        let iosRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let infoPlist = try String(
            contentsOf: iosRoot.appending(path: "HookahBoss/App/Configuration/Info.plist"),
            encoding: .utf8
        )

        XCTAssertTrue(infoPlist.contains("$(MARKETING_VERSION)"))
        XCTAssertTrue(infoPlist.contains("$(CURRENT_PROJECT_VERSION)"))
    }
}
