//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentityProvider
import hierarchical_state_machine_swift

@testable import AWSCognitoAuthPlugin

class VerifyPasswordSRPTests: XCTestCase {

    func testInitiatePasswordVerifier() {
        let verifyPasswordInvoked = expectation(description: "verifyPasswordInvoked")
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in verifyPasswordInvoked.fulfill() }
            )
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let command = VerifyPasswordSRP(stateData: SRPStateData.testData, authResponse: InitiateAuthOutputResponse.validTestData)

        command.execute(
            withDispatcher: MockDispatcher { _ in },
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testPasswordVerifierWithInvalidEnvironment() {

        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
                })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let command = VerifyPasswordSRP(stateData: SRPStateData.testData, authResponse: InitiateAuthOutputResponse.testData)

        let passwordVerifierError = expectation(description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            if case let .throwPasswordVerifierError(authenticationError) = event.eventType {
                XCTAssertNotNil(authenticationError)

                if case let .configuration(message) = authenticationError {
                    XCTAssertEqual(message, "Environment configured incorrectly")
                    passwordVerifierError.fulfill()
                }
                passwordVerifierError.fulfill()
            }
        }

        command.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testPasswordVerifierWithInvalidChallengeParams() {

        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
            })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let command = VerifyPasswordSRP(stateData: SRPStateData.testData, authResponse: InitiateAuthOutputResponse.testData)

        let passwordVerifierError = expectation(description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            if case let .throwPasswordVerifierError(authenticationError) = event.eventType {
                XCTAssertNotNil(authenticationError)
                if case let .service(message) = authenticationError {
                    XCTAssertEqual(message, "Unable to retrieve auth response challenge params")
                    passwordVerifierError.fulfill()
                }
            }
        }

        command.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testPasswordVerifierWithSaltNotPresent() {

        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
            })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let command = VerifyPasswordSRP(stateData: SRPStateData.testData, authResponse: InitiateAuthOutputResponse.invalidTestDataWithNoSalt)

        let passwordVerifierError = expectation(description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            if case let .throwPasswordVerifierError(authenticationError) = event.eventType {
                XCTAssertNotNil(authenticationError)
                if case let .service(message) = authenticationError {
                    //TODO: Change the test to look for error type instead of message.
                    XCTAssertEqual(message, "Unable to retrieve salt")
                    passwordVerifierError.fulfill()
                }
            }
        }

        command.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testPasswordVerifierWithSecretBlockNotPresent() {

        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
            })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let command = VerifyPasswordSRP(stateData: SRPStateData.testData, authResponse: InitiateAuthOutputResponse.invalidTestDataWithNoSecretBlock)

        let passwordVerifierError = expectation(description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            if case let .throwPasswordVerifierError(authenticationError) = event.eventType {
                XCTAssertNotNil(authenticationError)
                if case let .service(message) = authenticationError {
                    XCTAssertEqual(message, "Unable to retrieve server secrets")
                    passwordVerifierError.fulfill()
                }
            }
        }

        command.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testPasswordVerifierWithSRPBNotPresent() {

        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
            })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let command = VerifyPasswordSRP(stateData: SRPStateData.testData, authResponse: InitiateAuthOutputResponse.invalidTestDataWithNoSRPB)

        let passwordVerifierError = expectation(description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            if case let .throwPasswordVerifierError(authenticationError) = event.eventType {
                XCTAssertNotNil(authenticationError)
                if case let .service(message) = authenticationError {
                    XCTAssertEqual(message, "Unable to retrieve SRP_B")
                    passwordVerifierError.fulfill()
                }
            }
        }

        command.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testPasswordVerifierException() {

        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
            })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let command = VerifyPasswordSRP(stateData: SRPStateData.testData, authResponse: InitiateAuthOutputResponse.invalidTestDataForException)

        let passwordVerifierError = expectation(description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            if case let .throwPasswordVerifierError(authenticationError) = event.eventType {
                XCTAssertNotNil(authenticationError)
                if case let .service(message) = authenticationError {
                    XCTAssertEqual(message, "Exception calculating secret")
                    passwordVerifierError.fulfill()
                }
            }
        }

        command.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testSuccessfulInitiateAuthPropagatesSuccess() {
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
                })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let command = VerifyPasswordSRP(stateData: SRPStateData.testData, authResponse: InitiateAuthOutputResponse.validTestData)

        let passwordVerifierCompletion = expectation(description: "passwordVerifierCompletion")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            if case let .respondNextAuthChallenge(verifierResponse) = event.eventType {
                XCTAssertNotNil(verifierResponse)
                passwordVerifierCompletion.fulfill()
            }
        }

        command.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

}

private struct MockInvalidEnvironment: Environment { }
