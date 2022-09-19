//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

// Tests that the client behavior API calls pass through from Category to CategoryPlugin
class AnalyticsCategoryClientAPITests: XCTestCase {
    var analytics: AnalyticsCategory!
    var plugin: MockAnalyticsCategoryPlugin!

    override func setUp() async throws {
        await Amplify.reset()
        plugin = MockAnalyticsCategoryPlugin()
        analytics = Amplify.Analytics
        let categoryConfiguration = AnalyticsCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )
        let amplifyConfiguration = AmplifyConfiguration(analytics: categoryConfiguration)

        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(amplifyConfiguration)
        } catch let error as AmplifyError {
            XCTFail("setUp failed with error: \(error); \(error.errorDescription); \(error.recoverySuggestion)")
        } catch {
            XCTFail("setup failed with unknown error")
        }

    }

    func testIdentifyUser() throws {
        let expectedMessage = "identifyUser(test)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }

        analytics.identifyUser(userId: "test")
        waitForExpectations(timeout: 1.0)
    }

    func testRecordWithString() throws {
        let expectedMessage = "record(eventWithName:test)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.record(eventWithName: "test")
        waitForExpectations(timeout: 1.0)
    }

    func testRecordWithEvent() throws {
        let event = BasicAnalyticsEvent(name: "test")
        let expectedMessage = "record(event:test)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.record(event: event)
        waitForExpectations(timeout: 1.0)
    }

    func testRegisterGlobalProperties() throws {
        let expectedMessage = "registerGlobalProperties"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.registerGlobalProperties([:])
        waitForExpectations(timeout: 1.0)
    }

    func testUnregisterGlobalProperties() throws {
        let expectedMessage = "unregisterGlobalProperties(_:)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.unregisterGlobalProperties()
        waitForExpectations(timeout: 1.0)
    }

    func testUnregisterGlobalPropertiesWithVariadicParameter() throws {
        let expectedMessage = "unregisterGlobalProperties(_:)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.unregisterGlobalProperties("one", "two")
        waitForExpectations(timeout: 1.0)
    }

    func testFlushEvents() {
        let expectedMessage = "flushEvents()"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.flushEvents()
        waitForExpectations(timeout: 1.0)
    }

    func testDisable() {
        let expectedMessage = "disable()"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.disable()
        waitForExpectations(timeout: 1.0)
    }

    func testEnable() {
        let expectedMessage = "enable()"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.enable()
        waitForExpectations(timeout: 1.0)
    }
}
