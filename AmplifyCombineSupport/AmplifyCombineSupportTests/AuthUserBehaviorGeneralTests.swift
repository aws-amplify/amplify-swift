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

class AuthUserBehaviorTests: XCTestCase {

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

    func testConfirmUserAttributeSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.confirmUserAttribute = { _, _, _ in
            .successfulVoid
        }

        let sink = Amplify.Auth.confirm(userAttribute: .address, confirmationCode: "Test")
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

    func testConfirmUserAttributeFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.confirmUserAttribute = { _, _, _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.confirm(userAttribute: .address, confirmationCode: "Test")
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

    func testFetchUserAttributesSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.fetchUserAttributes = { _ in
            .success([])
        }

        let sink = Amplify.Auth.fetchUserAttributes()
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

    func testFetchUserAttributesFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.fetchUserAttributes = { _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.fetchUserAttributes()
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

    func testResendConfirmationCodeSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.resendConfirmationCode = { _, _ in
            .success(AuthCodeDeliveryDetails(destination: .email(nil)))
        }

        let sink = Amplify.Auth.resendConfirmationCode(for: .email)
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

    func testResendConfirmationCodeFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.resendConfirmationCode = { _, _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.resendConfirmationCode(for: .email)
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

    func testUpdatePasswordSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.updatePassword = { _, _, _ in
            .successfulVoid
        }

        let sink = Amplify.Auth.update(oldPassword: "test", to: "test")
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

    func testUpdatePasswordVoid() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.updatePassword = { _, _, _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.update(oldPassword: "test", to: "test")
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

    func testUpdateUserAttributeSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.updateUserAttribute = { _, _ in
            .success(AuthUpdateAttributeResult(isUpdated: true, nextStep: .done))
        }

        let attribute = AuthUserAttribute(.email, value: "test")
        let sink = Amplify.Auth.update(userAttribute: attribute)
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

    func testUpdateUserAttributeFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.updateUserAttribute = { _, _ in
            .failure(.unknown("Test"))
        }

        let attribute = AuthUserAttribute(.email, value: "test")
        let sink = Amplify.Auth.update(userAttribute: attribute)
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

    func testUpdateUserAttributesSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.updateUserAttributes = { _, _ in
            .success(
                [
                    AuthUserAttributeKey.email: AuthUpdateAttributeResult(isUpdated: true, nextStep: .done)
                ]
            )
        }

        let attribute = AuthUserAttribute(.email, value: "test")
        let sink = Amplify.Auth.update(userAttributes: [attribute])
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

    func testUpdateUserAttributesFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.updateUserAttributes = { _, _ in
            .failure(.unknown("Test"))
        }

        let attribute = AuthUserAttribute(.email, value: "test")
        let sink = Amplify.Auth.update(userAttributes: [attribute])
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
