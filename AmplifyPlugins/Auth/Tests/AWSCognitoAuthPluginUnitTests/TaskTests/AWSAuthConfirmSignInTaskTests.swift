//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class AuthenticationProviderConfirmSigninTests: BasePluginTest {

    override var initialState: AuthState {
        AuthState.configured(
            AuthenticationState.signingIn(.resolvingChallenge(.waitingForAnswer(.testData), .smsMfa)),
            AuthorizationState.sessionEstablished(.testData))
    }

    /// Test a successful confirmSignIn call with .done as next step
    ///
    /// - Given: an auth plugin with mocked service. Mocked service calls should mock a successul response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a successful result with .done as the next step
    ///
    func testSuccessfulConfirmSignIn() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
            return .testData()
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            let confirmSignInResult = try await plugin.confirmSignIn(challengeResponse: "code")
            guard case .done = confirmSignInResult.nextStep else {
                XCTFail("Result should be .done for next step")
                return
            }
            XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should be complete")
            resultExpectation.fulfill()
        } catch {
            XCTFail("Received failure with error \(error)")
        }
        wait(for: [resultExpectation], timeout: 2)
    }

    /// Test a confirmSignIn call with an empty confirmation code
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke confirmSignIn with an empty confirmation code
    /// - Then:
    ///    - I should get an .validation error
    ///
    func testSuccessfullyConfirmSignIn() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
            return .testData()
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "")
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should produce validation error instead of \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: 2)
    }
    
    /// Test a confirmSignIn call with an empty confirmation code followed by a second valaid confirmSignIn call
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a successul response
    /// - When:
    ///    - I invoke second confirmSignIn after confirmSignIn with an empty confirmation code
    /// - Then:
    ///    - I should get a successful result with .done as the next step
    ///
    func testSuccessfullyConfirmSignInAfterAFailedConfirmSignIn() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
            return .testData()
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "")
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should produce validation error instead of \(error)")
                return
            }
            
            do {
                let confirmSignInResult = try await plugin.confirmSignIn(challengeResponse: "code")
                XCTAssertTrue(confirmSignInResult.isSignedIn, "Signin result should be complete")
                resultExpectation.fulfill()
            } catch {
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: 2)
    }

    // MARK: Service error handling test

    /// Test a confirmSignIn call with aliasExistsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   aliasExistsException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .aliasExists as underlyingError
    ///
    func testConfirmSignInWithAliasExistsException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.aliasExistsException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .aliasExists = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be aliasExists \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with CodeMismatchException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeMismatchException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeMismatch as underlyingError
    ///
    func testConfirmSignInWithCodeMismatchException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.codeMismatchException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeMismatch = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeMismatch \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with CodeExpiredException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   CodeExpiredException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .codeExpired as underlyingError
    ///
    func testConfirmSignInWithExpiredCodeException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.expiredCodeException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .codeExpired = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be codeExpired \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with InternalErrorException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a InternalErrorException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get an .unknown error
    ///
    func testConfirmSignInWithInternalErrorException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.internalErrorException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce an unknown error instead of \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with InvalidLambdaResponseException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidLambdaResponseException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmSignInWithInvalidLambdaResponseException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.invalidLambdaResponseException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be lambda \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with InvalidParameterException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidParameterException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with  .invalidParameter as underlyingError
    ///
    func testConfirmSignInWithInvalidParameterException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.invalidParameterException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidParameter \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with InvalidPasswordException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidPasswordException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with  .invalidPassword as underlyingError
    ///
    func testConfirmSignInWithInvalidPasswordException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.invalidPasswordException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .invalidPassword = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidPassword \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with InvalidSmsRoleAccessPolicy response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   InvalidSmsRoleAccessPolicyException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a --
    ///
    func testConfirmSignInWithinvalidSmsRoleAccessPolicyException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.invalidSmsRoleAccessPolicyException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidPassword \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with InvalidSmsRoleTrustRelationship response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   CodeDeliveryFailureException response
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a --
    ///
    func testConfirmSignInWithInvalidSmsRoleTrustRelationshipException() async {
        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.invalidSmsRoleTrustRelationshipException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalidPassword \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    // TODO: Fix the test below

//    /// Test a confirmSignIn with User pool configuration from service
//    ///
//    /// - Given: an auth plugin with mocked service with no User Pool configuration
//    ///
//    /// - When:
//    ///    - I invoke confirmSignIn with a valid confirmation code
//    /// - Then:
//    ///    - I should get a .configuration error
//    ///
//    func testConfirmSignInWithInvalidUserPoolConfigurationException() {
//        let identityPoolConfigData = Defaults.makeIdentityConfigData()
//        let authorizationEnvironment = BasicAuthorizationEnvironment(
//            identityPoolConfiguration: identityPoolConfigData,
//            cognitoIdentityFactory: Defaults.makeIdentity)
//        let environment = AuthEnvironment(
//            configuration: .identityPools(identityPoolConfigData),
//            userPoolConfigData: nil,
//            identityPoolConfigData: identityPoolConfigData,
//            authenticationEnvironment: nil,
//            authorizationEnvironment: authorizationEnvironment,
//            logger: Amplify.Logging.logger(forCategory: "awsCognitoAuthPluginTest")
//        )
//        let stateMachine = Defaults.authStateMachineWith(environment: environment,
//                                                         initialState: initialState)
//        let plugin = AWSCognitoAuthPlugin()
//        plugin.configure(
//            authConfiguration: .identityPools(identityPoolConfigData),
//            authEnvironment: environment,
//            authStateMachine: stateMachine,
//            credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
//            hubEventHandler: MockAuthHubEventBehavior())
//       let resultExpectation = expectation(description: "Should receive a result")
//        _ = plugin.confirmSignIn(challengeResponse: "code") { result in
//            defer {
//                resultExpectation.fulfill()
//            }
//            switch result {
//            case .success(let signinResult):
//                XCTFail("Should not produce result - \(signinResult)")
//            case .failure(let error):
//                guard case .configuration = error else {
//                    XCTFail("Should produce configuration intead produced \(error)")
//                    return
//                }
//            }
//        }
//        wait(for: [resultExpectation], timeout: apiTimeout)
//    }

    /// Test a confirmSignIn with MFAMethodNotFoundException from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   MFAMethodNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with  .mfaMethodNotFound as underlyingError
    ///
    func testCofirmSignInWithMFAMethodNotFoundException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.mFAMethodNotFoundException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should not succeed")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .mfaMethodNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be mfaMethodNotFound \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with NotAuthorizedException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   NotAuthorizedException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .notAuthorized error
    ///
    func testConfirmSignInWithNotAuthorizedException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.notAuthorizedException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce notAuthorized error instead of \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn with PasswordResetRequiredException from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   PasswordResetRequiredException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .resetPassword as next step
    ///
    func testConfirmSignInWithPasswordResetRequiredException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.passwordResetRequiredException(
                    .init(message: "Exception"))
        })

        let resultExpectation = expectation(description: "Should receive a result")
        do {
            let confirmSignInResult = try await plugin.confirmSignIn(challengeResponse: "code")
            guard case .resetPassword = confirmSignInResult.nextStep else {
                XCTFail("Result should be .resetPassword for next step")
                return
            }
            resultExpectation.fulfill()
        } catch {
            XCTFail("Should not return error \(error)")
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with ResourceNotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   ResourceNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .resourceNotFound as underlyingError
    ///
    func testConfirmSignInWithResourceNotFoundException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.resourceNotFoundException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be resourceNotFound \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with SoftwareTokenMFANotFoundException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   SoftwareTokenMFANotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .softwareTokenMFANotEnabled as underlyingError
    ///
    func testConfirmSignInWithSoftwareTokenMFANotFoundException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.softwareTokenMFANotFoundException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .softwareTokenMFANotEnabled = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be softwareTokenMFANotEnabled \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with TooManyRequestsException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   TooManyRequestsException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .requestLimitExceeded as underlyingError
    ///
    func testConfirmSignInWithTooManyRequestsException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.tooManyRequestsException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be requestLimitExceeded \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with UnexpectedLambdaException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UnexpectedLambdaException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmSignInWithUnexpectedLambdaException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.unexpectedLambdaException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be lambda \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with UserLambdaValidationException response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserLambdaValidationException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .service error with .lambda as underlyingError
    ///
    func testConfirmSignInWithUserLambdaValidationException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.userLambdaValidationException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be lambda \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with UserNotConfirmedException response from service
    ///
    /// - Given: Given an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotConfirmedException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get .confirmSignUp as next step
    ///
    func testConfirmSignInWithUserNotConfirmedException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.userNotConfirmedException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        
        do {
            let confirmSignInResult = try await plugin.confirmSignIn(challengeResponse: "code")
            guard case .confirmSignUp = confirmSignInResult.nextStep else {
                XCTFail("Result should be .confirmSignUp for next step")
                return
            }
            resultExpectation.fulfill()
        } catch {
            XCTFail("Should not return error \(error)")
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test a confirmSignIn call with UserNotFound response from service
    ///
    /// - Given: an auth plugin with mocked service. Mocked service should mock a
    ///   UserNotFoundException response
    ///
    /// - When:
    ///    - I invoke confirmSignIn with a valid confirmation code
    /// - Then:
    ///    - I should get a .userNotFound error
    ///
    func testConfirmSignInWithUserNotFoundException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { _ in
                throw RespondToAuthChallengeOutputError.userNotFoundException(
                    .init(message: "Exception"))
        })
        let resultExpectation = expectation(description: "Should receive a result")
        do {
            _ = try await plugin.confirmSignIn(challengeResponse: "code")
            XCTFail("Should return an error if the result from service is invalid")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be userNotFound \(error)")
                return
            }
            resultExpectation.fulfill()
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }
}
