import XCTest

final class AuthTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAuth() throws {
        let app = XCUIApplication()
        app.launchArguments.append("test")
        app.launch()
        app.selectServer()
        app.buttons["Sort"].tapUnhittable()
        app.buttons["Old"].tap()
        XCTAssert(app.staticTexts["Comment Depth"].waitForExistence(timeout: 10))
        app.buttons["Accounts"].tap()
        let username = app.textFields["Username"]
        app.scrollTo(username)
        username.tap()
        username.typeText("mrlavallee\n")
        let password = app.secureTextFields["Password"]
        app.scrollTo(password)
        password.tap()
        password.typeText(ProcessInfo().environment["PASSWORD"]! + "\n")
        let submit = app.buttons["Submit"]
        app.scrollTo(submit)
        submit.tap()
        XCTAssert(app.staticTexts["Account Age"].waitForExistence(timeout: 10))
        app.buttons["Inbox"].tap()
        app.switches["Unread only"].tap()
        XCTAssert(app.staticTexts["tenth"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = app.launchArguments.dropLast()
        app.launch()
        let inbox = app.buttons["Inbox"]
        XCTAssert(inbox.waitForExistence(timeout: 10))
        inbox.tap()
        app.switches["Unread only"].tap()
        XCTAssert(app.staticTexts["tenth"].waitForExistence(timeout: 10))
    }
}
