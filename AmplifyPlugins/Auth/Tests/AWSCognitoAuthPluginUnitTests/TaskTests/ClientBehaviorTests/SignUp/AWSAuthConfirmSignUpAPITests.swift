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
@_spi(UnknownAWSHTTPServiceError) import AWSClientRuntime

class AWSAuthConfirmSignUpAPITests: BasePluginTest {

    let options = AuthConfirmSignUpRequest.Options()

    override var initialState: AuthState {
        AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured, 
            .awaitingUserConfirmation(SignUpEventData(username: "jeffb"), .init(.confirmUser())))
    }

    /// Given: Configured auth machine in `.awaitingUserConfirmation` sign up state and a mocked success response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up is complete with `.done` as the next step
    func testSuccessfulConfirmSignUp() async throws {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
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
    
    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked success response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up is complete with `.done` as the next step
    func testSuccessfulConfirmSignUpFromNotStartedState() async throws {
        let mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init()
            }
        )
        
        let initialStateAwaitingNotStarted = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .notStarted)
        
        
        let authPluginNotStarted = configureCustomPluginWith(
            userPool: { mockIdentityProvider },
            initialState: initialStateAwaitingNotStarted
        )

        let result = try await authPluginNotStarted.confirmSignUp(
            for: "jeffb",
            confirmationCode: "123456",
            options: options)

        guard case .done = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signin result should be complete")
    }
    
    /// Given: Configured auth machine in `.signedUp` sign up state and a mocked success response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up is complete with `.done` as the next step
    func testSuccessfulConfirmSignUpFromSignedUpState() async throws {
        let mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init()
            }
        )
        
        let initialStateSignedUp = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .signedUp(.init(username: "user1"), .init(.done)))
        
        
        let authPluginSignedUp = configureCustomPluginWith(
            userPool: { mockIdentityProvider },
            initialState: initialStateSignedUp
        )
        
        let result2 = try await authPluginSignedUp.confirmSignUp(
            for: "jeffb",
            confirmationCode: "123456",
            options: options)

        guard case .done = result2.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result2.isSignUpComplete, "Signin result should be complete")
    }
    
    /// Given: Configured auth machine in `.error` sign up state and a mocked success response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up is complete with `.done` as the next step
    func testSuccessfulConfirmSignUpFromErrorState() async throws {
        let mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init()
            }
        )

        let initialStateError = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .error(.service(error: AuthError.service("Unknown error", "Unknown error"))))
        
        let authPluginError = configureCustomPluginWith(userPool: { mockIdentityProvider },
                                                        initialState: initialStateError)

        let result = try await authPluginError.confirmSignUp(
            for: "jeffb",
            confirmationCode: "123456",
            options: options)

        guard case .done = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signin result should be complete")
    }
    
    /// Given: Configured auth machine in `.awaitingUserConfirmation` sign up state and a mocked success response
    /// with a `session` string
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up is complete with `.completeAutoSignIn` as the next step
    func testSuccessfulPasswordlessConfirmSignUp() async throws {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init(session: "session")
            }
        )

        let result = try await self.plugin.confirmSignUp(
            for: "jeffb",
            confirmationCode: "123456",
            options: options)

        guard case .completeAutoSignIn(let session) = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signin result should be complete")
        XCTAssertEqual(session, "session")
    }
    
    /// Given: Configured auth machine in `.notStarted` and a mocked success response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up is complete with `.completeAutoSignIn` as the next step
    func testSuccessfulPasswordlessConfirmSignUpFromNotStartedState() async throws {
        let mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init(session: "session")
            }
        )

        let initialStateAwaitingNotStarted = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .notStarted)
        
        
        let authPluginNotStarted = configureCustomPluginWith(
            userPool: { mockIdentityProvider },
            initialState: initialStateAwaitingNotStarted
        )

        let result = try await authPluginNotStarted.confirmSignUp(
            for: "jeffb",
            confirmationCode: "123456",
            options: options)

        guard case .completeAutoSignIn(let session) = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signin result should be complete")
        XCTAssertEqual(session, "session")
    }
    
    /// Given: Configured auth machine in `.notStarted` and a mocked success response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up is complete with `.completeAutoSignIn` as the next step
    func testSuccessfulPasswordlessConfirmSignUpFromSignedUpState() async throws {
        let mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init(session: "session")
            }
        )
        
        let initialStateSignedUp = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .signedUp(.init(username: "user1"), .init(.done)))
        
        
        let authPluginSignedUp = configureCustomPluginWith(
            userPool: { mockIdentityProvider },
            initialState: initialStateSignedUp
        )
        
        let result = try await authPluginSignedUp.confirmSignUp(
            for: "jeffb",
            confirmationCode: "123456",
            options: options)

        guard case .completeAutoSignIn(let session) = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signin result should be complete")
        XCTAssertEqual(session, "session")
    }
    
    /// Given: Configured auth machine in `.notStarted` and a mocked success response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up is complete with `.completeAutoSignIn` as the next step
    func testSuccessfulPasswordlessConfirmSignUpFromErrorState() async throws {
        let mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init(session: "session")
            }
        )
        
        let initialStateError = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .error(.service(error: AuthError.service("Unknown error", "Unknown error"))))
        
        let authPluginError = configureCustomPluginWith(userPool: { mockIdentityProvider },
                                                        initialState: initialStateError)

        let result = try await authPluginError.confirmSignUp(
            for: "jeffb",
            confirmationCode: "123456",
            options: options)

        guard case .completeAutoSignIn(let session) = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signin result should be complete")
        XCTAssertEqual(session, "session")
    }
    
    /// Given: Configured auth machine in `.awaitingUserConfirmation` sign up state and a mocked success response
    /// with a `nil` session string
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up is complete with `.done` as the next step
    func testSuccessfulPasswordlessConfirmSignUpWithNilSession() async throws {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init(session: nil)
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

    /// Given: Configured auth machine in `.awaitingUserConfirmation` sign up state and a mocked success response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked with options
    /// Then: Confirm Sign up is complete with `.done` as the next step
    func testSuccessfulConfirmSignUpWithOptions() async throws {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { request in
                XCTAssertNotNil(request.clientMetadata)
                XCTAssertEqual(request.clientMetadata?["key"], "value")
                XCTAssertEqual(request.forceAliasCreation, true)
                return .init()
            }
        )

        let pluginOptions = AWSAuthConfirmSignUpOptions(
            metadata: ["key": "value"],
            forceAliasCreation: true)
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

    /// Given: Configured auth machine in `.awaitingUserConfirmation` sign up state and a mocked success response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked with empty username
    /// Then: Confirm Sign up fails with error
    func testConfirmSignUpWithEmptyUsername() async {

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

    /// Given: Configured auth machine in `.awaitingUserConfirmation` sign up state and a mocked success response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked with empty confirmation code
    /// Then: Confirm Sign up fails with error
    func testConfirmSignUpWithEmptyConfirmationCode() async {

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

    /// Given: Configured auth machine in `.awaitingUserConfirmation` sign up state and a mocked service error response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up fails with appropriate error returned
    func testConfirmSignUpServiceError() async {

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
            (AWSCognitoIdentityProvider.TooManyFailedAttemptsException(), .failedAttemptsLimitExceeded)
        ]

        for errorToTest in errorsToTest {
            await validateConfirmSignUpServiceErrors(
                confirmSignUpOutputError: errorToTest.confirmSignUpOutputError,
                expectedCognitoError: errorToTest.cognitoError)
        }
    }

    /// Given: Configured auth machine in `.awaitingUserConfirmation` sign up state 
    /// and a mocked `NotAuthorizedException` response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up fails with `.notAuthorized` error
    func testConfirmSignUpWithNotAuthorizedException() async {

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

    /// Given: Configured auth machine in `.awaitingUserConfirmation` sign up state
    /// and a mocked `InternalErrorException` response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up fails with `.unknown` error
    func testConfirmSignUpWithInternalErrorException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockConfirmSignUpResponse: { _ in
                throw AWSCognitoIdentityProvider.InternalErrorException()
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

    /// Given: Configured auth machine in `.awaitingUserConfirmation` sign up state
    /// and a mocked unknown error response
    /// When: `Auth.confirmSignUp(for:confirmationCode:options:)` is invoked
    /// Then: Confirm Sign up fails with `.unknown` error
    func testConfirmSignUpWithUnknownErrorException() async {

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
