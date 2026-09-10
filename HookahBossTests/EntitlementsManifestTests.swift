import XCTest

final class EntitlementsManifestTests:XCTestCase {
    func testProjectDeclaresSignInWithAppleEntitlement()throws{
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let yaml=try String(contentsOf:root.appending(path:"project.yml"),encoding:.utf8)
        let plist=try String(contentsOf:root.appending(path:"HookahBoss/HookahBoss.entitlements"),encoding:.utf8)
        XCTAssertTrue(yaml.contains("CODE_SIGN_ENTITLEMENTS: HookahBoss/HookahBoss.entitlements"))
        XCTAssertTrue(plist.contains("com.apple.developer.applesignin"));XCTAssertTrue(plist.contains("Default"))
    }
}
