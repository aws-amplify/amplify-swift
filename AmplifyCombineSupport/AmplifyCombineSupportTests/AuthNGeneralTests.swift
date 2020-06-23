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

class AuthNGeneralTests: XCTestCase {

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

    func testConfirmResetPasswordSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.confirmResetPassword = { _, _, _, _ in
            .successfulVoid
        }

        let sink = Amplify.Auth.confirmResetPassword(for: "test", with: "test", confirmationCode: "test")
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

    func testConfirmResetPasswordFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.confirmResetPassword = { _, _, _, _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.confirmResetPassword(for: "test", with: "test", confirmationCode: "test")
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

    func testConfirmSignInSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.confirmSignIn = { _, _ in
            .success(AuthSignInResult(nextStep: .done))
        }

        let sink = Amplify.Auth.confirmSignIn(challengeResponse: "test")
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

    func testConfirmSignInFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.confirmSignIn = { _, _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.confirmSignIn(challengeResponse: "test")
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

    func testConfirmSignUpSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.confirmSignUp = { _, _, _ in
            .success(AuthSignUpResult(.done))
        }

        let sink = Amplify.Auth.confirmSignUp(for: "test", confirmationCode: "test")
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

    func testConfirmSignUpFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.confirmSignUp = { _, _, _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.confirmSignUp(for: "test", confirmationCode: "test")
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

    func testFetchAuthSessionSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        // swiftlint:disable:next nesting
        struct MockAuthSession: AuthSession {
            let isSignedIn = true
        }

        plugin.responders.fetchAuthSession = { _ in
            .success(MockAuthSession())
        }

        let sink = Amplify.Auth.fetchAuthSession()
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

    func testFetchAuthSessionFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.fetchAuthSession = { _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.fetchAuthSession()
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

    func testResendSignUpCodeSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.resendSignUpCode = { _, _ in
            .success(AuthCodeDeliveryDetails(destination: .email(nil)))
        }

        let sink = Amplify.Auth.resendSignUpCode(for: "test")
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

    func testResendSignUpCodeFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.resendSignUpCode = { _, _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.resendSignUpCode(for: "test")
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

    func testResetPasswordCodeSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.resetPassword = { _, _ in
            .success(AuthResetPasswordResult(isPasswordReset: true, nextStep: .done))
        }

        let sink = Amplify.Auth.resetPassword(for: "test")
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

    func testResetPasswordCodeFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.resetPassword = { _, _ in
            .failure(.unknown("Test"))
        }

        let sink = Amplify.Auth.resetPassword(for: "test")
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
