import XCTest

final class ScreenshotTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPosts() throws {
        let app = XCUIApplication()
        app.launchArguments.append("test")
        app.launch()
        let welcomeScreenshot = app.windows.firstMatch.screenshot()
        let welcomeAttachment = XCTAttachment(screenshot: welcomeScreenshot)
        welcomeAttachment.lifetime = .keepAlways
        add(welcomeAttachment)
        app.selectServer()
        XCTAssert(app.staticTexts["Comment Depth"].waitForExistence(timeout: 10))
        let normalScreenshot = app.windows.firstMatch.screenshot()
        let normalAttachment = XCTAttachment(screenshot: normalScreenshot)
        normalAttachment.lifetime = .keepAlways
        add(normalAttachment)
        app.buttons["Settings"].tap()
        let compact = app.switches["Compact Posts"]
        var count = 0
        let relativeTouchPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let relativeOffset = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: -1))
        while !compact.exists {
            relativeTouchPoint.press(forDuration: 0, thenDragTo: relativeOffset)
            XCTAssert(count < 10)
            count += 1
        }
        compact.switches.firstMatch.tap()
        app.buttons["Posts"].tap()
        XCTAssert(app.staticTexts["Comment Depth"].waitForExistence(timeout: 10))
        let compactScreenshot = app.windows.firstMatch.screenshot()
        let compactAttachment = XCTAttachment(screenshot: compactScreenshot)
        compactAttachment.lifetime = .keepAlways
        add(compactAttachment)
    }
}
