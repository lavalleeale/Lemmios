import XCTest

final class CommentTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
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
        app.scrollTo(showMore)
        XCTAssert(showMore.waitForExistence(timeout: 10))
        showMore.tap()
        XCTAssert(app.staticTexts["tenth"].waitForExistence(timeout: 10))
        let comment = app.staticTexts["first"]
        comment.tap()
        XCTAssert(!app.staticTexts["tenth"].isHittable)
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
        sleep(5)
        textFields["Server URL"].typeText("https://lemmy.lavallee.one\n")
    }

    func scrollTo(_ element: XCUIElement) {
        var count = 0
        let relativeTouchPoint = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let relativeOffset = coordinate(withNormalizedOffset: CGVector(dx: 0, dy: -1))
        while !element.exists {
            relativeTouchPoint.press(forDuration: 0, thenDragTo: relativeOffset)
            XCTAssert(count < 10)
            count += 1
        }
        relativeTouchPoint.press(forDuration: 0, thenDragTo: relativeOffset)
    }
}
