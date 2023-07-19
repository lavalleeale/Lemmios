import XCTest

final class FilterTest: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFilters() throws {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: ["test", "delete"])
        app.launch()
        app.selectServer()
        app.buttons["Sort"].tapUnhittable()
        app.buttons["Old"].tap()
        XCTAssert(app.staticTexts["Comment Depth"].waitForExistence(timeout: 10))
        app.buttons["Settings"].tap()
        app.buttons["Filters"].tap()
        app.buttons["Add Keyword"].tap()
        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText("Comment\n")
        app.buttons["Posts"].tap()
        app.buttons["Posts"].tap()
        app.buttons["All"].tap()
        app.buttons["Sort"].tapUnhittable()
        app.buttons["Old"].tap()
        XCTAssert(!app.staticTexts["Comment Depth"].waitForExistence(timeout: 10))
    }
}
