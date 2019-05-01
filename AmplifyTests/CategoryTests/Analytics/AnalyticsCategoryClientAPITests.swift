//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

// Tests that the client behavior API calls pass through from Category to CategoryPlugin
class AnalyticsCategoryClientAPITests: XCTestCase {
    var analytics: AnalyticsCategory!
    var plugin: MockAnalyticsCategoryPlugin!

    override func setUp() {
        Amplify.reset()
        plugin = MockAnalyticsCategoryPlugin()
        analytics = Amplify.Analytics
        let categoryConfiguration = BasicCategoryConfiguration(
            plugins: ["MockAnalyticsCategoryPlugin": true]
        )
        let amplifyConfiguration = BasicAmplifyConfiguration(analytics: categoryConfiguration)

        do {
            Amplify.add(plugin: plugin)
            try Amplify.configure(amplifyConfiguration)
        } catch let error as AmplifyError {
            XCTFail("setUp failed with error: \(error); \(error.errorDescription); \(error.recoverySuggestion)")
        } catch {
            XCTFail("setup failed with unknown error")
        }

    }

    func testRecordWithString() throws {
        let expectedMessage = "record(test)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.record("test")
        waitForExpectations(timeout: 1.0)
    }

    func testRecordWithEvent() throws {
        let event = BasicAnalyticsEvent("test")
        let expectedMessage = "record(event:test)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.record(event)
        waitForExpectations(timeout: 1.0)
    }

    func testRecordWithAttributes() throws {
        let event = BasicAnalyticsEvent("test")
        let expectedMessage = "record(event:test)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }
        analytics.record(event)
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

    func testUpdate() {
        let expectedMessage = "update(analyticsProfile:)"
        let methodInvoked = expectation(description: "Expected method was invoked on plugin")
        plugin.listeners.append { message in
            if message == expectedMessage {
                methodInvoked.fulfill()
            }
        }

        let mockAnalyticsProfile = "test"
        analytics.update(analyticsProfile: mockAnalyticsProfile)
        waitForExpectations(timeout: 1.0)
    }

}

extension String: AnalyticsProfile { }
