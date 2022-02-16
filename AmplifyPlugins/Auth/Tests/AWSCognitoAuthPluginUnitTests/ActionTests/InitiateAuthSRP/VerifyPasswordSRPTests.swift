//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentityProvider

@testable import AWSCognitoAuthPlugin

class VerifyPasswordSRPTests: XCTestCase {

    typealias CognitoFactory = BasicSRPAuthEnvironment.CognitoUserPoolFactory

    /// Test if valid input are given the service call is made
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid input
    /// - Then:
    ///    - Cognito client should invoke the api `respondToAuthChallengeCallback`
    ///
    func testInitiatePasswordVerifier() {
        let verifyPasswordInvoked = expectation(
            description: "verifyPasswordInvoked"
        )
        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback
                    in verifyPasswordInvoked.fulfill()
                })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let data = InitiateAuthOutputResponse.validTestData
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data)

        action.execute(
            withDispatcher: MockDispatcher { _ in },
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    /// Test empty response is returned by Cognito proper error is thrown
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid input and mock empty response from service
    /// - Then:
    ///    - Should send an event with proper error
    ///
    func testPasswordVerifierWithEmptyResponse() {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
                })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let data = InitiateAuthOutputResponse.validTestData
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data)

        let passwordVerifierError = expectation(description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            guard case let .throwPasswordVerifierError(error) = event.eventType,
                  case .invalidServiceResponse = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }

        }

        action.execute(withDispatcher: dispatcher, environment: environment)
        waitForExpectations(timeout: 0.1)
    }

    /// Test invalid challenge response from initiate auth
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid state but initiateAuth with invalid parameters
    /// - Then:
    ///    - Should send an event with proper error
    ///
    func testPasswordVerifierWithInvalidChallengeParams() {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
                })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let data = InitiateAuthOutputResponse.invalidChallenge
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data)

        let passwordVerifierError = expectation(
            description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            guard case let .throwPasswordVerifierError(error) = event.eventType,
                  case .invalidServiceResponse = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }
        }

        action.execute(withDispatcher: dispatcher, environment: environment)
        waitForExpectations(timeout: 0.1)
    }

    /// Test  challenge response with no salt from initiate auth
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid state but initiateAuth with no salt
    /// - Then:
    ///    - Should send an event with proper error
    ///
    func testPasswordVerifierWithSaltNotPresent() {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
                })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let data = InitiateAuthOutputResponse.invalidTestDataWithNoSalt
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data)

        let passwordVerifierError = expectation(
            description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            guard case let .throwPasswordVerifierError(error) = event.eventType,
                  case .invalidServiceResponse = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }
        }

        action.execute(withDispatcher: dispatcher, environment: environment)
        waitForExpectations(timeout: 0.1)
    }

    /// Test  challenge response with no secretblock from initiate auth
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid state but initiateAuth with no secretblock
    /// - Then:
    ///    - Should send an event with proper error
    ///
    func testPasswordVerifierWithSecretBlockNotPresent() {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
                })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let data = InitiateAuthOutputResponse.invalidTestDataWithNoSecretBlock
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data)

        let passwordVerifierError = expectation(
            description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            guard case let .throwPasswordVerifierError(error) = event.eventType,
                  case .invalidServiceResponse = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }
        }

        action.execute(withDispatcher: dispatcher, environment: environment)
        waitForExpectations(timeout: 0.1)
    }

    /// Test  challenge response with no SRPB from initiate auth
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid state but initiateAuth with no SRPB
    /// - Then:
    ///    - Should send an event with proper error
    ///
    func testPasswordVerifierWithSRPBNotPresent() {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
                })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let data = InitiateAuthOutputResponse.invalidTestDataWithNoSRPB
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data)

        let passwordVerifierError = expectation(
            description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            guard case let .throwPasswordVerifierError(error) = event.eventType,
                  case .invalidServiceResponse = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }
        }

        action.execute(withDispatcher: dispatcher, environment: environment)
        waitForExpectations(timeout: 0.1)
    }

    /// Test  an exception from the SRP calculation
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid state but invalid response for exception
    /// - Then:
    ///    - Should send an event with proper error
    ///
    func testPasswordVerifierException() {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(.success(RespondToAuthChallengeOutputResponse()))
                })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let data = InitiateAuthOutputResponse.invalidTestDataForException
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data)

        let passwordVerifierError = expectation(
            description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            guard case let .throwPasswordVerifierError(error) = event.eventType,
                  case .calculation = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }
        }

        action.execute(withDispatcher: dispatcher, environment: environment)
        waitForExpectations(timeout: 0.1)
    }

    /// Test  successful response from the VerifyPasswordSRP
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid input
    /// - Then:
    ///    - Should send an event with the result
    ///
    func testSuccessfulRespondToAuthChallengePropagatesSuccess() {
        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(
                        .success(
                            RespondToAuthChallengeOutputResponse.testData()
                        ))
                })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let data = InitiateAuthOutputResponse.validTestData
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data)

        let passwordVerifierCompletion = expectation(
            description: "passwordVerifierCompletion")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            if case let .finalizeSRPSignIn(signedInData) = event.eventType {
                XCTAssertNotNil(signedInData)
                passwordVerifierCompletion.fulfill()
            }
        }

        action.execute(withDispatcher: dispatcher, environment: environment)
        waitForExpectations(timeout: 0.1)
    }

    /// Test  successful response from the VerifyPasswordSRP
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid input and mock error from service
    /// - Then:
    ///    - Should send an event with service error
    ///
    func testRespondToAuthChallengePropagatesError() {
        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                respondToAuthChallengeCallback: { input, callback in
                    callback(
                        .failure(.unknown(nil))
                    )
                })
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let data = InitiateAuthOutputResponse.validTestData
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data)

        let passwordVerifierError = expectation(
            description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent but got \(event)")
                return
            }

            guard case let .throwPasswordVerifierError(error) = event.eventType,
                  case .service = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }
        }

        action.execute(withDispatcher: dispatcher, environment: environment)
        waitForExpectations(timeout: 0.1)
    }

}
