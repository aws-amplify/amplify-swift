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

}
