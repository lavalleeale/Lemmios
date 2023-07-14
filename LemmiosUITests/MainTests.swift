import XCTest

final class MainTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testSearch() throws {
        let app = XCUIApplication()
        app.launchArguments.append("test")
        app.launch()
        app.selectServer()
        app.textFields["All"].tap()
        app.textFields["All"].typeText("artemis")
        XCTAssert(app.staticTexts["artemistesting"].waitForExistence(timeout: 10))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Search"].tap()
        app.textFields["Search"].tap()
        app.textFields["Search"].typeText("com\n")
        XCTAssert(app.staticTexts["Comment Depth"].waitForExistence(timeout: 10))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.textFields["Search"].tap()
        app.textFields["Search"].typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3)
 + "alex")
        app.buttons["Users with \"alex\""].tap()
        XCTAssert(app.staticTexts["alex95712"].waitForExistence(timeout: 10))
    }

    func testComments() throws {
        let app = XCUIApplication()
        app.launchArguments.append("test")
        app.launch()
        app.selectServer()
        app.textFields["All"].tap()
        app.textFields["All"].typeText("artemistesting\n")
        app.buttons["Sort"].tapUnhittable()
        app.buttons["Old"].tap()
        let postPredicate = NSPredicate(format: "label CONTAINS[c] %@", "Comment Depth")
        let post = app.buttons.containing(postPredicate).firstMatch
        post.tap()
        let showMore = app.buttons["Show 2 More"]
        XCTAssert(showMore.waitForExistence(timeout: 10))
            showMore.tap()
        XCTAssert(app.staticTexts["tenth"].waitForExistence(timeout: 10))
        let comment = app.staticTexts["first"]
        comment.tap()
        XCTAssert(!app.staticTexts["tenth"].isHittable)
    }

    func testAuth() throws {
        let app = XCUIApplication()
        app.launchArguments.append("test")
        app.launch()
        app.selectServer()
        app.buttons["Accounts"].tap()
        app.textFields["Username"].tap()
        app.textFields["Username"].typeText("mrlavallee")
        app.textFields["Password"].tap()
        app.secureTextFields["Password"].typeText(ProcessInfo().environment["PASSWORD"]!)
        app.buttons.matching(identifier: "Login").allElementsBoundByIndex[0].tap()
        XCTAssert(app.staticTexts["Account Age"].waitForExistence(timeout: 10))
        app.buttons["Inbox"].tap()
        app.switches["Unread only"].tap()
        XCTAssert(app.staticTexts["tenth"].waitForExistence(timeout: 10))
    }
}

extension XCUIElement {
    func tapUnhittable() {
        XCTContext.runActivity(named: "Tap \(self) by coordinate") { _ in
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}

extension XCUIApplication {
    func selectServer() {
        buttons["I Have an Instance"].tap()
        buttons["Server, https://lemmy.world"].tap()
        buttons["custom"].tap()
        textFields["Server URL"].tap()
        textFields["Server URL"].typeText("https://lemmy.lavallee.one")
        buttons["Submit"].tap()
    }
}
