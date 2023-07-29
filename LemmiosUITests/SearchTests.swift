import XCTest

final class SearchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSearch() throws {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: ["test", "delete"])
        app.launch()
        app.selectServer()
        app.textFields["All"].tap()
        app.textFields["All"].typeText("artemis")
        XCTAssert(app.staticTexts["artemistesting"].waitForExistence(timeout: 10))
        app.textFields["All"].typeText("\n")
        app.buttons["Search"].tap()
        app.textFields["Search"].tap()
        app.textFields["Search"].typeText("com\n")
        app.buttons["Sort"].tapUnhittable()
        app.buttons["Old"].tap()
        XCTAssert(app.staticTexts["Comment Depth"].waitForExistence(timeout: 10))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.textFields["Search"].tap()
        app.textFields["Search"].typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "alex\n")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Users with \"alex\""].tap()
        XCTAssert(app.buttons["alex95712"].waitForExistence(timeout: 10))
    }
}
