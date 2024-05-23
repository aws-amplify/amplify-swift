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

    func testIdentifyUser() async throws {
        let expectedMessage = "identifyUser(test)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }

        analytics.identifyUser(userId: "test")
        await fulfillment(of: [methodInvoked], timeout: 1)
    }

    func testRecordWithString() async throws {
        let expectedMessage = "record(eventWithName:test)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.record(eventWithName: "test")
        await fulfillment(of: [methodInvoked], timeout: 1)
    }

    func testRecordWithEvent() async throws {
        let event = BasicAnalyticsEvent(name: "test")
        let expectedMessage = "record(event:test)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.record(event: event)
        await fulfillment(of: [methodInvoked], timeout: 1)
    }

    func testRegisterGlobalProperties() async throws {
        let expectedMessage = "registerGlobalProperties"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.registerGlobalProperties([:])
        await fulfillment(of: [methodInvoked], timeout: 1)
    }

    func testUnregisterGlobalProperties() async throws {
        let expectedMessage = "unregisterGlobalProperties(_:)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.unregisterGlobalProperties()
        await fulfillment(of: [methodInvoked], timeout: 1)
    }

    func testUnregisterGlobalPropertiesWithVariadicParameter() async throws {
        let expectedMessage = "unregisterGlobalProperties(_:)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.unregisterGlobalProperties("one", "two")
        await fulfillment(of: [methodInvoked], timeout: 1)
    }
    
    func testUnregisterGlobalPropertiesWithArrayParameter() async throws {
        let expectedMessage = "unregisterGlobalProperties(_:)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        let properties: [String] = ["one", "two"]
        analytics.unregisterGlobalProperties(properties)
        await fulfillment(of: [methodInvoked], timeout: 1)
    }

    func testFlushEvents() async {
        let expectedMessage = "flushEvents()"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.flushEvents()
        await fulfillment(of: [methodInvoked], timeout: 1)
    }

    func testDisable() async {
        let expectedMessage = "disable()"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.disable()
        await fulfillment(of: [methodInvoked], timeout: 1)
    }

    func testEnable() async {
        let expectedMessage = "enable()"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.enable()
        await fulfillment(of: [methodInvoked], timeout: 1)
    }
}
