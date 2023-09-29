//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentityProvider
import AWSClientRuntime
@testable import AWSPluginsTestCommon
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
    func testInitiatePasswordVerifier() async {
        let verifyPasswordInvoked = expectation(
            description: "verifyPasswordInvoked"
        )
        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    verifyPasswordInvoked.fulfill()
                    return RespondToAuthChallengeOutputResponse()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutputResponse.validTestData
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data,
                                       clientMetadata: [:])

        await action.execute(
            withDispatcher: MockDispatcher { _ in },
            environment: environment
        )

        await waitForExpectations(timeout: 0.1)
    }

    /// Test empty response is returned by Cognito proper error is thrown
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid input and mock empty response from service
    /// - Then:
    ///    - Should send an event with proper error
    ///
    func testPasswordVerifierWithEmptyResponse() async {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    return RespondToAuthChallengeOutputResponse()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutputResponse.validTestData
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data,
                                       clientMetadata: [:])

        let passwordVerifierError = expectation(description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent but got \(event)")
                return
            }

            guard case let .throwAuthError(error) = event.eventType,
                  case .invalidServiceResponse = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }

        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await waitForExpectations(timeout: 0.1)
    }

    /// Test invalid challenge response from initiate auth
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid state but initiateAuth with invalid parameters
    /// - Then:
    ///    - Should send an event with proper error
    ///
    func testPasswordVerifierWithInvalidChallengeParams() async {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    return RespondToAuthChallengeOutputResponse()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutputResponse.invalidChallenge
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data,
                                       clientMetadata: [:])

        let passwordVerifierError = expectation(
            description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent but got \(event)")
                return
            }

            guard case let .throwPasswordVerifierError(error) = event.eventType,
                  case .invalidServiceResponse = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await waitForExpectations(timeout: 0.1)
    }

    /// Test  challenge response with no salt from initiate auth
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid state but initiateAuth with no salt
    /// - Then:
    ///    - Should send an event with proper error
    ///
    func testPasswordVerifierWithSaltNotPresent() async {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    return RespondToAuthChallengeOutputResponse()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutputResponse.invalidTestDataWithNoSalt
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data,
                                       clientMetadata: [:])

        let passwordVerifierError = expectation(
            description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent but got \(event)")
                return
            }

            guard case let .throwPasswordVerifierError(error) = event.eventType,
                  case .invalidServiceResponse = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await waitForExpectations(timeout: 0.1)
    }

    /// Test  challenge response with no secretblock from initiate auth
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid state but initiateAuth with no secretblock
    /// - Then:
    ///    - Should send an event with proper error
    ///
    func testPasswordVerifierWithSecretBlockNotPresent() async {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    return RespondToAuthChallengeOutputResponse()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutputResponse.invalidTestDataWithNoSecretBlock
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data,
                                       clientMetadata: [:])

        let passwordVerifierError = expectation(
            description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent but got \(event)")
                return
            }

            guard case let .throwPasswordVerifierError(error) = event.eventType,
                  case .invalidServiceResponse = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await waitForExpectations(timeout: 0.1)
    }

    /// Test  challenge response with no SRPB from initiate auth
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid state but initiateAuth with no SRPB
    /// - Then:
    ///    - Should send an event with proper error
    ///
    func testPasswordVerifierWithSRPBNotPresent() async {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    return RespondToAuthChallengeOutputResponse()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutputResponse.invalidTestDataWithNoSRPB
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data,
                                       clientMetadata: [:])

        let passwordVerifierError = expectation(
            description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent but got \(event)")
                return
            }

            guard case let .throwPasswordVerifierError(error) = event.eventType,
                  case .invalidServiceResponse = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await waitForExpectations(timeout: 0.1)
    }

    /// Test  an exception from the SRP calculation
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid state but invalid response for exception
    /// - Then:
    ///    - Should send an event with proper error
    ///
    func testPasswordVerifierException() async {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    return RespondToAuthChallengeOutputResponse()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutputResponse.invalidTestDataForException
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data,
                                       clientMetadata: [:])

        let passwordVerifierError = expectation(
            description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent but got \(event)")
                return
            }

            guard case let .throwPasswordVerifierError(error) = event.eventType,
                  case .calculation = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await waitForExpectations(timeout: 0.1)
    }

    /// Test  successful response from the VerifyPasswordSRP
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid input
    /// - Then:
    ///    - Should send an event with the result
    ///
    func testSuccessfulRespondToAuthChallengePropagatesSuccess() async {
        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    return RespondToAuthChallengeOutputResponse.testData()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutputResponse.validTestData
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data,
                                       clientMetadata: [:])

        let passwordVerifierCompletion = expectation(
            description: "passwordVerifierCompletion")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent but got \(event)")
                return
            }

            if case let .finalizeSignIn(signedInData) = event.eventType {
                XCTAssertNotNil(signedInData)
                passwordVerifierCompletion.fulfill()
            }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await waitForExpectations(timeout: 0.1)
    }

    /// Test  successful response from the VerifyPasswordSRP
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid input and mock error from service
    /// - Then:
    ///    - Should send an event with service error
    ///
    func testRespondToAuthChallengePropagatesError() async {
        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    throw try AWSClientRuntime.UnknownAWSHTTPServiceError(
                        httpResponse: MockHttpResponse.ok,
                        message: nil,
                        requestID: nil,
                        requestID2: nil,
                        typeName: nil
                    )
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutputResponse.validTestData
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data,
                                       clientMetadata: [:])

        let passwordVerifierError = expectation(
            description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent but got \(event)")
                return
            }

            guard case let .throwAuthError(error) = event.eventType,
                  case .service = error
            else {
                      XCTFail("Should receive invalid service response")
                      return
                  }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await waitForExpectations(timeout: 0.1)
    }

    /// Test verify password retry on device not found
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid input and mock empty device not found error from Cognito
    /// - Then:
    ///    - Should send an event with retryRespondPasswordVerifier
    ///
    func testPasswordVerifierWithDeviceNotFound() async {

        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    throw AWSCognitoIdentityProvider.ResourceNotFoundException()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutputResponse.validTestData
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data,
                                       clientMetadata: [:])

        let passwordVerifierError = expectation(description: "passwordVerifierError")

        let dispatcher = MockDispatcher { event in
            defer { passwordVerifierError.fulfill() }

            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent but got \(event)")
                return
            }

            guard case .retryRespondPasswordVerifier = event.eventType
            else {
                XCTFail("Should receive retryRespondPasswordVerifier")
                return
            }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await waitForExpectations(timeout: 0.1)
    }

    /// Test  successful response from the VerifyPasswordSRP for confirmDevice
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid input and mock new device
    /// - Then:
    ///    - Should send an event confirmDevice
    ///
    func testRespondToAuthChallengeWithConfirmDevice() async {
        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    return RespondToAuthChallengeOutputResponse.testDataWithNewDevice()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutputResponse.validTestData
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data,
                                       clientMetadata: [:])

        let passwordVerifierCompletion = expectation(
            description: "passwordVerifierCompletion")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent but got \(event)")
                return
            }

            if case .confirmDevice(let signedInData) = event.eventType {
                XCTAssertNotNil(signedInData)
                passwordVerifierCompletion.fulfill()
            }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await waitForExpectations(timeout: 0.1)
    }

    /// Test  successful response from the VerifyPasswordSRP for verifyDevice
    ///
    /// - Given: VerifyPasswordSRP action with mocked cognito client and configuration
    /// - When:
    ///    - I invoke the action with valid input and mock verify device as response
    /// - Then:
    ///    - Should send an event initiateDeviceSRP
    ///
    func testRespondToAuthChallengeWithVerifyDevice() async {
        let identityProviderFactory: CognitoFactory = {
            MockIdentityProvider(
                mockRespondToAuthChallengeResponse: { _ in
                    return RespondToAuthChallengeOutputResponse.testDataWithVerifyDevice()
                })
        }

        let environment = Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)

        let data = InitiateAuthOutputResponse.validTestData
        let action = VerifyPasswordSRP(stateData: SRPStateData.testData,
                                       authResponse: data,
                                       clientMetadata: [:])

        let passwordVerifierCompletion = expectation(
            description: "passwordVerifierCompletion")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignInEvent else {
                XCTFail("Expected event to be SignInEvent but got \(event)")
                return
            }

            if case .initiateDeviceSRP(_, let response) = event.eventType {
                XCTAssertNotNil(response)
                passwordVerifierCompletion.fulfill()
            }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)
        await waitForExpectations(timeout: 0.1)
    }

}
