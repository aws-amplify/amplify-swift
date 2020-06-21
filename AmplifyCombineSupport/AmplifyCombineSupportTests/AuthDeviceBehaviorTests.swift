//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyCombineSupport

@testable import Amplify
@testable import AmplifyTestCommon

class AuthDeviceBehaviorTests: XCTestCase {

    var plugin: MockAuthCategoryPlugin!

    override func setUpWithError() throws {
        Amplify.reset()

        let categoryConfig = AuthCategoryConfiguration(
            plugins: ["MockAuthCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(auth: categoryConfig)
        plugin = MockAuthCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(amplifyConfig)
    }

    func testFetchDeviceSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.fetchDevices = { _ in
            .success([])
        }

        let sink = Amplify.Auth.fetchDevices()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testFetchDeviceFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.fetchDevices = { _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.fetchDevices()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testForgetDeviceSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.forgetDevice = { _, _ in
            .successfulVoid
        }

        let sink = Amplify.Auth.forgetDevice()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testForgetDeviceFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.forgetDevice = { _, _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.forgetDevice()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testRememberDeviceSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.rememberDevice = { _ in
            .successfulVoid
        }

        let sink = Amplify.Auth.rememberDevice()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testRememberDeviceFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.rememberDevice = { _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.rememberDevice()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

}
