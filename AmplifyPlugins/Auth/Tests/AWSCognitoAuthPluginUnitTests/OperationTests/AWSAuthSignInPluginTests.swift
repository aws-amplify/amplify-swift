//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentity
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

class AWSAuthSignInPluginTests: BasePluginTest {

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)
    }

    /// Test a signIn with valid inputs
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .done response
    ///
    func testSuccessfulSignIn() {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutputResponse(
                authenticationResult: .init(
                    accessToken: "accessToken",
                    expiresIn: 300,
                    idToken: "idToken",
                    newDeviceMetadata: nil,
                    refreshToken: "refreshToken",
                    tokenType: ""),
                challengeName: .none,
                challengeParameters: [:],
                session: "session")
        })

        let pluginOptions = AWSAuthSignInOptions(validationData: ["somekey": "somevalue"],
                                                 metadata: ["somekey": "somevalue"])
        let options = AuthSignInRequest.Options(pluginOptions: pluginOptions)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .done = signinResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(signinResult.isSignedIn, "Signin result should be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with valid inputs and authflow type
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with valid values
    /// - Then:
    ///    - I should get a .done response
    ///
    func testSuccessfulSignInWithAuthFlow() {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutputResponse(
                authenticationResult: .init(
                    accessToken: "accessToken",
                    expiresIn: 300,
                    idToken: "idToken",
                    newDeviceMetadata: nil,
                    refreshToken: "refreshToken",
                    tokenType: ""),
                challengeName: .none,
                challengeParameters: [:],
                session: "session")
        })

        let pluginOptions = AWSAuthSignInOptions(validationData: ["somekey": "somevalue"],
                                                 metadata: ["somekey": "somevalue"],
                                                 authFlowType: .userSRP)
        let options = AuthSignInRequest.Options(pluginOptions: pluginOptions)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .done = signinResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(signinResult.isSignedIn, "Signin result should be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with empty username
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with empty username
    /// - Then:
    ///    - I should get a .validation error
    ///
    func testSignInWithEmptyUsername() {

        self.mockIdentityProvider = MockIdentityProvider()

        let options = AuthSignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not receive a success response \(signinResult)")
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should receive validation error instead got \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with empty password
    ///
    /// - Given: Given an auth plugin with mocked service.
    ///
    /// - When:
    ///    - I invoke signIn with no password
    /// - Then:
    ///    - I should get a valid response
    ///
    func testSignInWithEmptyPassword() {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutputResponse(
                authenticationResult: .init(
                    accessToken: "accessToken",
                    expiresIn: 300,
                    idToken: "idToken",
                    newDeviceMetadata: nil,
                    refreshToken: "refreshToken",
                    tokenType: ""),
                challengeName: .none,
                challengeParameters: [:],
                session: "session")
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .done = signinResult.nextStep else {
                    XCTFail("Result should be .done for next step")
                    return
                }
                XCTAssertTrue(signinResult.isSignedIn, "Signin result should be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with nil as reponse from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mock nil response from service
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testSignInWithInvalidResult() {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse()
        })
        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not receive a success response \(signinResult)")
            case .failure(let error):
                guard case .service = error else {
                    XCTFail("Should receive unknown error instead got \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with smsMFA as signIn result response
    ///
    /// - Given: Given an auth plugin with mocked service. Mock smsMFA response for signIn result
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .confirmSignInWithSMSMFACode
    ///
    func testSignInWithNextStepSMS() {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutputResponse(
                authenticationResult: .none,
                challengeName: .smsMfa,
                challengeParameters: [:],
                session: "session")
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .confirmSignInWithSMSMFACode = signinResult.nextStep else {
                    XCTFail("Result should be .confirmSignInWithSMSMFACode for next step")
                    return
                }
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with additional info in next step
    ///
    /// - Given: Given an auth plugin with mocked service. Mock additional info in custom auth
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a the info in next step
    ///
    func testCustomAuthWithAdditionalInfo() {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutputResponse(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: ["paramKey": "value"],
                session: "session")
        })

        let pluginOptions = AWSAuthSignInOptions(validationData: ["somekey": "somevalue"],
                                                 metadata: ["somekey": "somevalue"],
                                                 authFlowType: .customWithSRP)
        let options = AuthSignInRequest.Options(pluginOptions: pluginOptions)
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .confirmSignInWithCustomChallenge(let additionalInfo) = signinResult.nextStep else {
                    XCTFail("Result should be .confirmSignInWithCustomChallenge for next step")
                    return
                }
                guard let addditionalValue = additionalInfo?["paramKey"] else {
                    XCTFail("Additional info should be passed to the result")
                    return
                }
                XCTAssertEqual(addditionalValue, "value", "Additional info should be same")
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with additional info in next step
    ///
    /// - Given: Given an auth plugin with mocked service. Mock additional info in sms mfa
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a the info in next step
    ///
    func testSMSMFAWithAdditionalInfo() {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutputResponse(
                authenticationResult: .none,
                challengeName: .smsMfa,
                challengeParameters: ["paramKey": "value"],
                session: "session")
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .confirmSignInWithSMSMFACode(_, let additionalInfo) = signinResult.nextStep else {
                    XCTFail("Result should be .confirmSignInWithSMSMFACode for next step")
                    return
                }
                guard let addditionalValue = additionalInfo?["paramKey"] else {
                    XCTFail("Additional info should be passed to the result")
                    return
                }
                XCTAssertEqual(addditionalValue, "value", "Additional info should be same")
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /* TODO: Enable tests when newPasswordRequired challenge is supported

    /// Test a signIn with newPassword as signIn result response
    ///
    /// - Given: Given an auth plugin with mocked service. Mock newPassword response for signIn result
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .confirmSignInWithNewPassword error
    ///
    func testSignInWithNextStepNewPassword() {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutputResponse(
                authenticationResult: .none,
                challengeName: .newPasswordRequired,
                challengeParameters: ["paramKey": "value"],
                session: "session")
        })

        let options = AuthSignInRequest.Options()

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .confirmSignInWithNewPassword = signinResult.nextStep else {
                    XCTFail("Result should be .confirmSignInWithNewPassword for next step")
                    return
                }
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }


    /// Test a signIn with additional info in next step
    ///
    /// - Given: Given an auth plugin with mocked service. Mock additional info in new password
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a the info in next step
    ///
    func testNewPasswordWithAdditionalInfo() {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutputResponse(
                authenticationResult: .none,
                challengeName: .newPasswordRequired,
                challengeParameters: ["paramKey": "value"],
                session: "session")
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .confirmSignInWithNewPassword(let additionalInfo) = signinResult.nextStep else {
                    XCTFail("Result should be .confirmSignInWithNewPassword for next step")
                    return
                }
                guard let addditionalValue = additionalInfo?["paramKey"] else {
                    XCTFail("Additional info should be passed to the result")
                    return
                }
                XCTAssertEqual(addditionalValue, "value", "Additional info should be same")
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }
     */

    /// Test a signIn with customChallenge as signIn result response
    ///
    /// - Given: Given an auth plugin with mocked service. Mock customChallenge response for signIn result
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .confirmSignInWithCustomChallenge
    ///
    func testSignInWithNextStepCustomChallenge() {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutputResponse(
                authenticationResult: .none,
                challengeName: .customChallenge,
                challengeParameters: ["paramKey": "value"],
                session: "session")
        })

        let pluginOptions = AWSAuthSignInOptions(authFlowType: .customWithSRP)
        let options = AuthSignInRequest.Options(pluginOptions: pluginOptions)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .confirmSignInWithCustomChallenge = signinResult.nextStep else {
                    XCTFail("Result should be .confirmSignInWithCustomChallenge for next step")
                    return
                }
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with invalid response
    ///
    /// - Given: Given an auth plugin with mocked service. Mock unknown response for signIn result
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testSignInWithNextStepUnknown() {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            RespondToAuthChallengeOutputResponse(
                authenticationResult: .none,
                challengeName: .sdkUnknown("no idea"),
                challengeParameters: ["paramKey": "value"],
                session: "session")
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):

                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce unknown error")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // MARK: - Service error for initiateAuth

    /// Test a signIn with `InternalErrorException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InternalErrorException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .unknown error
    ///
    func testSignInWithInternalErrorException() {

        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw InitiateAuthOutputError.internalErrorException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce unknown error")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `InvalidLambdaResponseException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .lambda error
    ///
    func testSignInWithInvalidLambdaResponseException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw InitiateAuthOutputError.invalidLambdaResponseException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce lambda error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `InvalidParameterException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .invalidParameter error
    ///
    func testSignInWithInvalidParameterException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw InitiateAuthOutputError.invalidParameterException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce invalidParameter error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `InvalidUserPoolConfigurationException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidUserPoolConfigurationException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .configuration error
    ///
    func testSignInWithInvalidUserPoolConfigurationException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw InitiateAuthOutputError.invalidUserPoolConfigurationException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .configuration = error else {
                    XCTFail("Should produce configuration intead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `NotAuthorizedException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testSignInWithNotAuthorizedException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw InitiateAuthOutputError.notAuthorizedException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .notAuthorized = error else {
                    XCTFail("Should produce notAuthorized error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `PasswordResetRequiredException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .resetPassword as next step
    ///
    func testSignInWithPasswordResetRequiredException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw InitiateAuthOutputError.passwordResetRequiredException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .resetPassword = signinResult.nextStep else {
                    XCTFail("Result should be .resetPassword for next step")
                    return
                }
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Should not produce error - \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `ResourceNotFoundException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound error
    ///
    func testSignInWithResourceNotFoundException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw InitiateAuthOutputError.resourceNotFoundException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce resourceNotFound error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `TooManyRequestsException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded error
    ///
    func testSignInWithTooManyRequestsException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw InitiateAuthOutputError.tooManyRequestsException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce requestLimitExceeded error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `UnexpectedLambdaException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .lambda error
    ///
    func testSignInWithUnexpectedLambdaException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw InitiateAuthOutputError.unexpectedLambdaException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce lambda error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `UserLambdaValidationException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .lambda error
    ///
    func testSignInWithUserLambdaValidationException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw InitiateAuthOutputError.userLambdaValidationException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce lambda error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `UserNotConfirmedException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .confirmSignUp as next step
    ///
    func testSignInWithUserNotConfirmedException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw InitiateAuthOutputError.userNotConfirmedException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                guard case .confirmSignUp = signinResult.nextStep else {
                    XCTFail("Result should be .confirmSignUp for next step")
                    return
                }
                XCTAssertFalse(signinResult.isSignedIn, "Signin result should not be complete")
            case .failure(let error):
                XCTFail("Should not produce error - \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `UserNotFoundException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .userNotFound error
    ///
    func testSignInWithUserNotFoundException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            throw InitiateAuthOutputError.userNotFoundException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce userNotFound error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // MARK: - Service error for RespondToAuthChallenge

    /// Test a signIn with `AliasExistsException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   AliasExistsException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .aliasExists error
    ///
    func testSignInWithAliasExistsException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            throw RespondToAuthChallengeOutputError.aliasExistsException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .aliasExists = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce aliasExists error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a signIn with `InvalidPasswordException` from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidPasswordException response for signIn
    ///
    /// - When:
    ///    - I invoke signIn
    /// - Then:
    ///    - I should get a .service error with .invalidPassword error
    ///
    func testSignInWithInvalidPasswordException() {
        self.mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutputResponse(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutputResponse.validChalengeParams,
                session: "someSession")
        }, mockRespondToAuthChallengeResponse: { _ in
            throw RespondToAuthChallengeOutputError.invalidPasswordException(.init())
        })

        let options = AuthSignInRequest.Options()
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.signIn(username: "username", password: "password", options: options) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let signinResult):
                XCTFail("Should not produce result - \(signinResult)")
            case .failure(let error):
                guard case .service(_, _, let underlyingError) = error,
                      case .invalidPassword = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce invalidPassword error but instead produced \(error)")
                    return
                }
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }
}
