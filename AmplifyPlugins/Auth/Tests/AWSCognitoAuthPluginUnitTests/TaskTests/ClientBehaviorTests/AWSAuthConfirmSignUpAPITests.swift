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
import ClientRuntime
import AWSClientRuntime

class AWSAuthConfirmSignUpAPITests: BasePluginTest {

    let options = AuthConfirmSignUpRequest.Options()

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)
    }

    func testSuccessfulSignUp() async throws {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { _ in
                return .init()
            }
        )

        let result = try await self.plugin.confirmSignUp(
            for: "jeffb",
            confirmationCode: "123456",
            options: options)

        guard case .done = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signin result should be complete")
    }

    func testSuccessfulSignUpWithOptions() async throws {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { request in
                XCTAssertNotNil(request.clientMetadata)
                XCTAssertEqual(request.clientMetadata?["key"], "value")
                return .init()
            }
        )

        let pluginOptions = AWSAuthConfirmSignUpOptions(metadata: ["key": "value"])
        let options = AuthConfirmSignUpRequest.Options(pluginOptions: pluginOptions)
        let result = try await self.plugin.confirmSignUp(
            for: "jeffb",
            confirmationCode: "123456",
            options: options)

        guard case .done = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signin result should be complete")
    }

    func testSignUpWithEmptyUsername() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { _ in
                XCTFail("Sign up API should not be called")
                return .init()
            }
        )

        do {
            let _ = try await self.plugin.confirmSignUp(
                for: "",
                confirmationCode: "123456",
                options: options)

        } catch {
            guard let authError = error as? AuthError else {
                XCTFail("Result should not be nil")
                return
            }
            XCTAssertEqual(authError, AuthError.validation("", "", "", nil))
        }
    }

    func testSignUpWithEmptyConfirmationCode() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { _ in
                XCTFail("Sign up API should not be called")
                return .init()
            }
        )

        do {
            let _ = try await self.plugin.confirmSignUp(
                for: "jeffb",
                confirmationCode: "",
                options: options)

        } catch {
            guard let authError = error as? AuthError else {
                XCTFail("Result should not be nil")
                return
            }
            XCTAssertEqual(authError, AuthError.validation("", "", "", nil))
        }
    }

    func testSignUpServiceError() async {

        let errorsToTest: [(confirmSignUpOutputError: Error, cognitoError: AWSCognitoAuthError)] = [
            (AWSCognitoIdentityProvider.AliasExistsException(), .aliasExists),
            (AWSCognitoIdentityProvider.CodeMismatchException(), .codeMismatch),
            (AWSCognitoIdentityProvider.InvalidLambdaResponseException(), .lambda),
            (AWSCognitoIdentityProvider.InvalidParameterException(), .invalidParameter),
            (AWSCognitoIdentityProvider.ResourceNotFoundException(), .resourceNotFound),
            (AWSCognitoIdentityProvider.TooManyRequestsException(), .requestLimitExceeded),
            (AWSCognitoIdentityProvider.UnexpectedLambdaException(), .lambda),
            (AWSCognitoIdentityProvider.UserLambdaValidationException(), .lambda),
            (AWSCognitoIdentityProvider.UserNotFoundException(), .userNotFound),
            (AWSCognitoIdentityProvider.LimitExceededException(), .limitExceeded),
            (AWSCognitoIdentityProvider.TooManyFailedAttemptsException(), .failedAttemptsLimitExceeded),
        ]

        for errorToTest in errorsToTest {
            await validateConfirmSignUpServiceErrors(
                confirmSignUpOutputError: errorToTest.confirmSignUpOutputError,
                expectedCognitoError: errorToTest.cognitoError)
        }
    }

    func testSignUpWithNotAuthorizedException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { _ in
                throw AWSCognitoIdentityProvider.NotAuthorizedException()
            }
        )

        do {
            let _ = try await self.plugin.confirmSignUp(
                for: "jeffb",
                confirmationCode: "12345",
                options: options)
        } catch {
            guard let authError = error as? AuthError else {
                XCTFail("Should throw Auth error")
                return
            }

            guard case .notAuthorized(let errorDescription,
                                      let recoverySuggestion,
                                      let notAuthorizedError) = authError else {
                XCTFail("Auth error should be of type notAuthorized")
                return
            }

            XCTAssertNotNil(errorDescription)
            XCTAssertNotNil(recoverySuggestion)
            XCTAssertNil(notAuthorizedError)
        }
    }

    func testSignUpWithInternalErrorException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { _ in
                throw try await AWSCognitoIdentityProvider.InternalErrorException(
                    httpResponse: .init(body: .empty, statusCode: .accepted)
                )
            }
        )

        do {
            let _ = try await self.plugin.confirmSignUp(
                for: "jeffb",
                confirmationCode: "12345",
                options: options)
        } catch {
            guard let authError = error as? AuthError else {
                XCTFail("Should throw Auth error")
                return
            }

            guard case .unknown(let errorMessage, _) = authError else {
                XCTFail("Auth error should be of type unknown")
                return
            }

            XCTAssertNotNil(errorMessage)
        }
    }

    func testSignUpWithUnknownErrorException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { _ in
                throw AWSClientRuntime.UnknownAWSHTTPServiceError.init(
                    httpResponse: .init(body: .empty, statusCode: .accepted),
                    message: nil,
                    requestID: nil,
                    typeName: nil
                )
            }
        )

        do {
            let _ = try await self.plugin.confirmSignUp(
                for: "jeffb",
                confirmationCode: "12345",
                options: options)
        } catch {
            guard let authError = error as? AuthError else {
                XCTFail("Should throw Auth error")
                return
            }

            guard case .unknown(let errorMessage, _) = authError else {
                XCTFail("Auth error should be of type unknown")
                return
            }

            XCTAssertNotNil(errorMessage)
        }
    }

    func validateConfirmSignUpServiceErrors(
        confirmSignUpOutputError: Error,
        expectedCognitoError: AWSCognitoAuthError) async {
            print(confirmSignUpOutputError, expectedCognitoError)
            self.mockIdentityProvider = MockIdentityProvider(
                mockConfirmSignUpResponse: { _ in
                    throw confirmSignUpOutputError
                }
            )

            do {
                let _ = try await self.plugin.confirmSignUp(
                    for: "jeffb",
                    confirmationCode: "12345",
                    options: options)
            } catch {
                guard let authError = error as? AuthError else {
                    XCTFail("Should throw Auth error")
                    return
                }

                guard case .service(let errorMessage,
                                    let recovery,
                                    let serviceError) = authError else {
                    XCTFail("Auth error should be of type service error")
                    return
                }

                XCTAssertNotNil(errorMessage)
                XCTAssertNotNil(recovery)

                guard let awsCognitoAuthError = serviceError as? AWSCognitoAuthError else {
                    XCTFail("Service error wrapped should be of type AWSCognitoAuthError")
                    return
                }
                XCTAssertEqual(awsCognitoAuthError, expectedCognitoError)
            }
        }
}
