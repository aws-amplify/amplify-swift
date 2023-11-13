//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSCognitoAuthPlugin




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
            (AliasExistsException(name: nil, message: nil, httpURLResponse: .init()), .aliasExists),
            (CodeMismatchException(name: nil, message: nil, httpURLResponse: .init()), .codeMismatch),
            (InvalidLambdaResponseException(name: nil, message: nil, httpURLResponse: .init()), .lambda),
            (InvalidParameterException(name: nil, message: nil, httpURLResponse: .init()), .invalidParameter),
            (ResourceNotFoundException(name: nil, message: nil, httpURLResponse: .init()), .resourceNotFound),
            (TooManyRequestsException(name: nil, message: nil, httpURLResponse: .init()), .requestLimitExceeded),
            (UnexpectedLambdaException(name: nil, message: nil, httpURLResponse: .init()), .lambda),
            (UserLambdaValidationException(name: nil, message: nil, httpURLResponse: .init()), .lambda),
            (UserNotFoundException(name: nil, message: nil, httpURLResponse: .init()), .userNotFound),
            (LimitExceededException(name: nil, message: nil, httpURLResponse: .init()), .limitExceeded),
            (TooManyFailedAttemptsException(name: nil, message: nil, httpURLResponse: .init()), .failedAttemptsLimitExceeded)
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
                throw NotAuthorizedException(
                    name: nil,
                    message: nil,
                    httpURLResponse: .init()
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
                throw InternalErrorException(
                    name: nil,
                    message: nil,
                    httpURLResponse: .init()
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
                throw PlaceholderError()
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
