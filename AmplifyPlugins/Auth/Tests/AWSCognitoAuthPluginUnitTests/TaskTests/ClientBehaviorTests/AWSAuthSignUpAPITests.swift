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

class AWSAuthSignUpAPITests: BasePluginTest {

    let options = AuthSignUpRequest.Options(userAttributes: [
        .init(.email, value: "random@random.com")
    ])

    override var initialState: AuthState {
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)
    }

    func testSuccessfulSignUp() async throws {

        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(codeDeliveryDetails: nil,
                             userConfirmed: true,
                             userSub: UUID().uuidString)
            }
        )

        let result = try await self.plugin.signUp(
            username: "jeffb",
            password: "Valid&99",
            options: options)

        guard case .done = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signin result should be complete")
    }

    func testSignUpWithEmptyUsername() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                XCTFail("Sign up API should not be called")
                return .init(codeDeliveryDetails: nil, userConfirmed: true, userSub: nil)
            }
        )

        do { _ = try await self.plugin.signUp(
            username: "",
            password: "Valid&99",
            options: options)

        } catch {
            guard let authError = error as? AuthError else {
                XCTFail("Result should not be nil")
                return
            }
            XCTAssertEqual(authError, AuthError.validation("Username", "", "", nil))
        }
    }

    func testSignUpWithUserConfirmationRequired() async throws {

        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: .init(
                        attributeName: "some attribute",
                        deliveryMedium: .email,
                        destination: "random@random.com"),
                    userConfirmed: false,
                    userSub: "userId")
            }
        )

        let result = try await self.plugin.signUp(
            username: "jeffb",
            password: "Valid&99",
            options: options)

        guard case .confirmUser(let deliveryDetails, let additionalInfo, let userId) = result.nextStep else {
            XCTFail("Result should be .confirmUser for next step")
            return
        }

        XCTAssertNotNil(deliveryDetails?.destination)
        XCTAssertEqual(deliveryDetails?.attributeKey, .unknown("some attribute"))
        XCTAssertEqual(additionalInfo, nil)
        XCTAssertEqual(userId, "userId")
        XCTAssertFalse(result.isSignUpComplete, "Signin result should be complete")
    }

    func testSignUpNilCognitoResponse() async throws {

        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: nil,
                    userConfirmed: false,
                    userSub: nil)
            }
        )

        let result = try await self.plugin.signUp(
            username: "jeffb",
            password: "Valid&99",
            options: options)

        guard case .confirmUser(let deliveryDetails, let additionalInfo, let userId) = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }

        XCTAssertNil(deliveryDetails?.destination)
        XCTAssertNil(deliveryDetails?.attributeKey)
        XCTAssertEqual(additionalInfo, nil)
        XCTAssertEqual(userId, nil)
        XCTAssertFalse(result.isSignUpComplete, "Signin result should be complete")
    }

    func testSignUpServiceError() async {

        let errorsToTest: [(signUpOutputError: SignUpOutputError, cognitoError: AWSCognitoAuthError)] = [
            (.codeDeliveryFailureException(.init()), .codeDelivery),
            (.invalidEmailRoleAccessPolicyException(.init()), .emailRole),
            (.invalidLambdaResponseException(.init()), .lambda),
            (.invalidParameterException(.init()), .invalidParameter),
            (.invalidPasswordException(.init()), .invalidPassword),
            (.invalidSmsRoleAccessPolicyException(.init()), .smsRole),
            (.invalidSmsRoleTrustRelationshipException(.init()), .smsRole),
            (.resourceNotFoundException(.init()), .resourceNotFound),
            (.tooManyRequestsException(.init()), .requestLimitExceeded),
            (.unexpectedLambdaException(.init()), .lambda),
            (.userLambdaValidationException(.init()), .lambda),
            (.usernameExistsException(.init()), .usernameExists),
        ]

        for errorToTest in errorsToTest {
            await validateSignUpServiceErrors(
                signUpOutputError: errorToTest.signUpOutputError,
                expectedCognitoError: errorToTest.cognitoError)
        }
    }

    func testSignUpWithNotAuthorizedException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                throw SignUpOutputError.notAuthorizedException(.init())
            }
        )

        do {
            _ = try await self.plugin.signUp(
                username: "username",
                password: "Valid&99",
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
            mockSignUpResponse: { _ in
                throw SignUpOutputError.internalErrorException(.init())
            }
        )

        do {
            _ = try await self.plugin.signUp(
                username: "username",
                password: "Valid&99",
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

    func validateSignUpServiceErrors(
        signUpOutputError: SignUpOutputError,
        expectedCognitoError: AWSCognitoAuthError) async {
            self.mockIdentityProvider = MockIdentityProvider(
                mockSignUpResponse: { _ in
                    throw signUpOutputError
                }
            )

            do {
                _ = try await self.plugin.signUp(
                    username: "username",
                    password: "Valid&99",
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
