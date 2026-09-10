import XCTest

@MainActor
final class HookahBossSmokeUITests:XCTestCase {
    private func launch(language:String,dark:Bool,bypassAge:Bool=true,accessibilityXXXL:Bool=false)->XCUIApplication {
        let app=XCUIApplication();app.launchEnvironment["HOOKAHBOSS_UI_TEST"]="1";app.launchEnvironment["HOOKAHBOSS_UI_TEST_BYPASS_AGE"]=bypassAge ? "1":"0"
        app.launchArguments += [bypassAge ? "--ui-test-bypass-age":"--ui-test-age-gate","-AppleLanguages","(\(language))","-AppleLocale",language=="ru" ? "ru_RU":"en_US"]
        if dark { app.launchArguments += ["-AppleInterfaceStyle","Dark"] }
        if accessibilityXXXL { app.launchArguments += ["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"] }
        app.launch();return app
    }

    func testAgeGateEnglish() {
        let app=launch(language:"en",dark:false,bypassAge:false)
        let confirm=element(app,"age.confirm")
        XCTAssertTrue(confirm.waitForExistence(timeout:5), "The age confirmation control must exist")
        XCTAssertTrue(confirm.isHittable, "The age confirmation control must be tappable")
    }

    func testAnonymousEnglishLightSmoke() { runAnonymousSmoke(language:"en",mixes:"Mixes",articles:"Articles",create:"Create",my:"My",cancel:"Cancel") }
    func testAnonymousRussianDarkSmoke() { runAnonymousSmoke(language:"ru",mixes:"Миксы",articles:"Статьи",create:"Создать",my:"Моё",cancel:"Отмена",dark:true) }

    func testAnonymousEnglishAccessibilityXXXL() {
        let app=launch(language:"en",dark:false,accessibilityXXXL:true)
        XCTAssertTrue(element(app,"screen.home").waitForExistence(timeout:5))
        let mixesTab=app.tabBars.buttons["Mixes"];XCTAssertTrue(mixesTab.isHittable);mixesTab.tap();XCTAssertTrue(mixesTab.isSelected)
        let card=element(app,"mix.card.10000000-0000-0000-0000-000000000001");XCTAssertTrue(card.waitForExistence(timeout:5));XCTAssertTrue(scrollToHittable(card,in:app));card.tap()
        XCTAssertTrue(element(app,"screen.mixDetail").waitForExistence(timeout:5));let composition=element(app,"mix.composition");XCTAssertTrue(composition.waitForExistence(timeout:5));XCTAssertTrue(scrollToHittable(composition,in:app));app.swipeDown();app.swipeDown();app.buttons["Back"].tap()
        let filters=app.buttons["mix.filters"];XCTAssertTrue(filters.isHittable);filters.tap();XCTAssertTrue(element(app,"screen.filters").waitForExistence(timeout:5));let apply=app.buttons["filters.apply"];XCTAssertTrue(scrollToHittable(apply,in:app));apply.tap();XCTAssertTrue(element(app,"screen.mixResults").waitForExistence(timeout:5))
        app.tabBars.buttons["Articles"].tap();XCTAssertTrue(element(app,"screen.articles").waitForExistence(timeout:5));let article=element(app,"article.row.guide");XCTAssertTrue(article.waitForExistence(timeout:5));XCTAssertTrue(scrollToHittable(article,in:app));article.tap();XCTAssertTrue(element(app,"screen.articleReader").waitForExistence(timeout:5))
        app.tabBars.buttons["Create"].tap();XCTAssertTrue(element(app,"auth.sheet").waitForExistence(timeout:5));let cancel=app.buttons["Cancel"];XCTAssertTrue(scrollToHittable(cancel,in:app));cancel.tap()
        app.tabBars.buttons["My"].tap();if element(app,"auth.sheet").waitForExistence(timeout:2){let dismiss=app.buttons["Cancel"];XCTAssertTrue(scrollToHittable(dismiss,in:app));dismiss.tap()};XCTAssertTrue(element(app,"screen.mySignedOut").waitForExistence(timeout:5));XCTAssertFalse(app.buttons["admin.entry"].exists)
    }

    private func runAnonymousSmoke(language:String,mixes:String,articles:String,create:String,my:String,cancel:String,dark:Bool=false,file:StaticString=#filePath,line:UInt=#line) {
        let app=launch(language:language,dark:dark)
        XCTAssertTrue(element(app,"screen.home").waitForExistence(timeout:5),file:file,line:line)
        let mixesTab=app.tabBars.buttons[mixes]
        XCTAssertTrue(mixesTab.waitForExistence(timeout:5),file:file,line:line)
        XCTAssertTrue(mixesTab.isHittable,file:file,line:line)
        mixesTab.tap()
        XCTAssertTrue(mixesTab.isSelected,file:file,line:line)
        let card=element(app,"mix.card.10000000-0000-0000-0000-000000000001")
        XCTAssertTrue(card.waitForExistence(timeout:5),file:file,line:line)
        XCTAssertTrue(card.isHittable,file:file,line:line)
        card.tap()
        XCTAssertTrue(element(app,"screen.mixDetail").waitForExistence(timeout:5),file:file,line:line)
        app.buttons[language=="ru" ? "Назад":"Back"].tap()
        app.buttons["mix.filters"].tap();XCTAssertTrue(element(app,"screen.filters").waitForExistence(timeout:5),file:file,line:line);let apply=app.buttons["filters.apply"];XCTAssertTrue(apply.isHittable,file:file,line:line);apply.tap();XCTAssertTrue(element(app,"screen.mixResults").waitForExistence(timeout:5),file:file,line:line)
        app.tabBars.buttons[articles].tap();XCTAssertTrue(element(app,"screen.articles").waitForExistence(timeout:5),file:file,line:line);let article=app.buttons["article.row.guide"];XCTAssertTrue(article.waitForExistence(timeout:5),file:file,line:line);article.tap();XCTAssertTrue(element(app,"screen.articleReader").waitForExistence(timeout:5),file:file,line:line)
        app.tabBars.buttons[create].tap();XCTAssertTrue(element(app,"auth.sheet").waitForExistence(timeout:5),file:file,line:line);app.buttons[cancel].tap()
        app.tabBars.buttons[my].tap();if element(app,"auth.sheet").waitForExistence(timeout:2){app.buttons[cancel].tap()};XCTAssertTrue(element(app,"screen.mySignedOut").waitForExistence(timeout:5),file:file,line:line);XCTAssertFalse(app.buttons["admin.entry"].exists,file:file,line:line)
    }
    private func element(_ app:XCUIApplication,_ identifier:String)->XCUIElement { app.descendants(matching:.any)[identifier] }
    private func scrollToHittable(_ target:XCUIElement,in app:XCUIApplication,attempts:Int=6)->Bool { for _ in 0..<attempts { if target.isHittable{return true};app.swipeUp() };return target.isHittable }
}
