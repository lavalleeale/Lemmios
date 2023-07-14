
import Foundation
import XCTest

import Ambassador
import Embassy

class BaseUITest: XCTestCase {
    let port = 8080
    var router: Router!
    var eventLoop: SelectorEventLoop!
    var server: HTTPServer!
    var app: XCUIApplication!

    var eventLoopThreadCondition: NSCondition!
    var eventLoopThread: Thread!

    override func setUp() {
        super.setUp()
        setupWebApp()
        setupApp()
    }

    // setup the Embassy web server for testing
    private func setupWebApp() {
        eventLoop = try! SelectorEventLoop(selector: try! KqueueSelector())
        router = Router()
        server = DefaultHTTPServer(eventLoop: eventLoop, port: port, app: router.app)

        // Start HTTP server to listen on the port
        try! server.start()

        eventLoopThreadCondition = NSCondition()
        eventLoopThread = Thread(target: self, selector: #selector(runEventLoop), object: nil)
        eventLoopThread.start()
    }

    // set up XCUIApplication
    private func setupApp() {
        app = XCUIApplication()
        app.launchArguments += ["UI-Testing"]
    }

    override func tearDown() {
        super.tearDown()
        app.terminate()
        server.stopAndWait()
        eventLoopThreadCondition.lock()
        eventLoop.stop()
        while eventLoop.running {
            if !eventLoopThreadCondition.wait(until: Date().addingTimeInterval(10)) {
                fatalError("Join eventLoopThread timeout")
            }
        }
    }

    @objc private func runEventLoop() {
        eventLoop.runForever()
        eventLoopThreadCondition.lock()
        eventLoopThreadCondition.signal()
        eventLoopThreadCondition.unlock()
    }
}
