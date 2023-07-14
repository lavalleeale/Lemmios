import XCTest

final class SearchTests: XCTestCase {
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
        app.textFields["All"].typeText("\n")
        app.buttons["Search"].tap()
        app.textFields["Search"].tap()
        app.textFields["Search"].typeText("com\n")
        XCTAssert(app.staticTexts["Comment Depth"].waitForExistence(timeout: 10))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.textFields["Search"].tap()
        app.textFields["Search"].typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3)
            + "alex\n")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Users with \"alex\""].tap()
        XCTAssert(app.staticTexts["alex95712"].waitForExistence(timeout: 10))
    }
}
