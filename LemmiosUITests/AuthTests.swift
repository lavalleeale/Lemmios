import XCTest

final class AuthTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test01Login() throws {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: ["test", "delete"])
        app.launch()
        app.selectServer()
        app.buttons["Sort"].tapUnhittable()
        app.buttons["Old"].tap()
        XCTAssert(app.staticTexts["Comment Depth"].waitForExistence(timeout: 10))
        app.buttons["Accounts"].tap()
        let username = app.textFields["Username"]
        app.type(username, text: "mrlavallee")
        let password = app.secureTextFields["Password"]
        app.type(password, text: ProcessInfo().environment["PASSWORD"]!.dropLast())
        let submit = app.buttons["Submit"]
        app.scrollTo(submit)
        submit.tap()
        XCTAssert(app.staticTexts["Password Incorrect"].waitForExistence(timeout: 10))
        app.type(password, text: ProcessInfo().environment["PASSWORD"]!)
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

    func test02Creation() throws {
        let postTitle = UUID().uuidString
        let app = XCUIApplication()
        app.launchArguments.append("test")
        app.launch()
        app.textFields["All"].tap()
        app.textFields["All"].typeText("artemistesting\n")
        app.buttons["More Options"].tapUnhittable()
        app.buttons["Submit Post"].tap()
        app.type(app.textFields["Title"], text: postTitle)
        app.buttons["Text (optional)"].tap()
        app.textViews.firstMatch.tap()
        app.textViews.firstMatch.typeText("body for \(postTitle)")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Post"].tap()
        let posted = app.staticTexts["Posted! Tap to view."]
        XCTAssert(posted.waitForExistence(timeout: 10))
        posted.tap()
        app.buttons["More"].tapUnhittable()
        app.buttons["Delete"].tap()
        XCTAssert(app.staticTexts["deleted by creator"].waitForExistence(timeout: 10))
        app.buttons["More"].tapUnhittable()
        app.buttons["Restore"].tap()
        XCTAssert(app.staticTexts["body for \(postTitle)"].waitForExistence(timeout: 10))
        app.buttons["More"].tapUnhittable()
        app.buttons["Edit"].tap()
        app.buttons["body for \(postTitle)"].tap()
        app.textViews.firstMatch.coordinate(withNormalizedOffset: CGVectorMake(0.9, 0.9)).tap()
        app.textViews.firstMatch.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "body for \(postTitle)".count * 5) + "edited body for \(postTitle)")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Post"].tap()
        XCTAssert(app.staticTexts["edited body for \(postTitle)"].waitForExistence(timeout: 10))
        app.buttons["Reply"].tap()
        app.textViews.firstMatch.tap()
        app.textViews.firstMatch.typeText("comment")
        app.buttons["Done"].tap()
        XCTAssert(app.staticTexts["comment"].waitForExistence(timeout: 10))
    }
}
