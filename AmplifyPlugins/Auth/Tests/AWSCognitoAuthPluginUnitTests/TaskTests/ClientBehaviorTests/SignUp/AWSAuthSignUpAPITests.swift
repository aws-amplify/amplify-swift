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
        AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)
    }

    /// Given: Configured auth machine in `.notStarted` sign up states and a mocked success response
    /// When: `Auth.signUp(username:password:options:)` is invoked
    /// Then: Sign up is successful with `.done` as the next step
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
    
    /// Given: Configured auth machine in `.awaitingUserConfirmation` sign up state and a mocked success response
    /// When: `Auth.signUp(username:password:options:)` is invoked
    /// Then: Sign up is successful with `.done` as the next step
    func testSuccessfulSignUpFromAwaitingUserConfirmationState() async throws {
        let mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(codeDeliveryDetails: nil,
                             userConfirmed: true,
                             userSub: UUID().uuidString)
            }
        )
        
        let initialStateAwaitingUserConfirmation = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .awaitingUserConfirmation(.init(username: "user1"), .init(.confirmUser())))
        
        
        let authPluginAwaitingUserConfirmation = configureCustomPluginWith(
            userPool: { mockIdentityProvider },
            initialState: initialStateAwaitingUserConfirmation
        )

        let result = try await authPluginAwaitingUserConfirmation.signUp(
            username: "user2",
            password: "Valid&99",
            options: options)

        guard case .done = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signup result should be complete")
    }
    
    /// Given: Configured auth machine in `.signedUp` sign up state and a mocked success response
    /// When: `Auth.signUp(username:password:options:)` is invoked
    /// Then: Sign up is successful with `.done` as the next step
    func testSuccessfulSignUpFromSignedUpState() async throws {
        let mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(codeDeliveryDetails: nil,
                             userConfirmed: true,
                             userSub: UUID().uuidString)
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

        let result = try await authPluginSignedUp.signUp(
            username: "user2",
            password: "Valid&99",
            options: options)

        guard case .done = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signup result should be complete")
    }
    
    /// Given: Configured auth machine in `.error` sign up state and a mocked success response
    /// When: `Auth.signUp(username:password:options:)` is invoked
    /// Then: Sign up is successful with `.done` as the next step
    func testSuccessfulSignUpFromErrorState() async throws {
        let mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(codeDeliveryDetails: nil,
                             userConfirmed: true,
                             userSub: UUID().uuidString)
            }
        )
        
        let initialStateError = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .error(.service(error: AuthError.service("Unknown error", "Unknown error"))))
        
        let authPluginError = configureCustomPluginWith(userPool: { mockIdentityProvider },
                                                        initialState: initialStateError)

        let result = try await authPluginError.signUp(
            username: "user2",
            password: "Valid&99",
            options: options)

        guard case .done = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signup result should be complete")
    }
    
    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked success response
    /// When: `Auth.signUp(username:password:options:)` is invoked without a password
    /// Then: Sign up is successful with `.done` as the next step
    func testSuccessfulPasswordlessSignUp() async throws {

        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(codeDeliveryDetails: nil,
                             userConfirmed: true,
                             userSub: UUID().uuidString)
            }
        )

        let result = try await self.plugin.signUp(
            username: "jeffb",
            options: options)

        guard case .done = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signin result should be complete")
    }
    
    /// Given: Configured auth machine in `.awaitingUserConfirmation` sign up state and a mocked success response
    /// When: `Auth.signUp(username:password:options:)` is invoked without password
    /// Then: Sign up is successful with `.done` as the next step
    func testSuccessfulPasswordlessSignUpFromAwaitingUserConfirmationState() async throws {
        let mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(codeDeliveryDetails: nil,
                             userConfirmed: true,
                             userSub: UUID().uuidString)
            }
        )
        
        let initialStateAwaitingUserConfirmation = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .awaitingUserConfirmation(.init(username: "user1"), .init(.confirmUser())))
        
        
        let authPluginAwaitingUserConfirmation = configureCustomPluginWith(
            userPool: { mockIdentityProvider },
            initialState: initialStateAwaitingUserConfirmation
        )

        let result1 = try await authPluginAwaitingUserConfirmation.signUp(
            username: "user2",
            options: options)

        guard case .done = result1.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result1.isSignUpComplete, "Signup result should be complete")
    }
    
    /// Given: Configured auth machine in `.signedUp` sign up state and a mocked success response
    /// When: `Auth.signUp(username:password:options:)` is invoked without password
    /// Then: Sign up is successful with `.done` as the next step
    func testSuccessfulPasswordlessSignUpFromSignedUpState() async throws {
        let mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(codeDeliveryDetails: nil,
                             userConfirmed: true,
                             userSub: UUID().uuidString)
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

        let result = try await authPluginSignedUp.signUp(
            username: "user2",
            options: options)

        guard case .done = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signup result should be complete")
    }
    
    /// Given: Configured auth machine in `.error` sign up state and a mocked success response
    /// When: `Auth.signUp(username:password:options:)` is invoked without password
    /// Then: Sign up is successful with `.done` as the next step
    func testSuccessfulPasswordlessSignUpFromErrorState() async throws {
        let mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(codeDeliveryDetails: nil,
                             userConfirmed: true,
                             userSub: UUID().uuidString)
            }
        )
        
        let initialStateError = AuthState.configured(
            .signedOut(.init(lastKnownUserName: nil)),
            .configured,
            .error(.service(error: AuthError.service("Unknown error", "Unknown error"))))
        
        let authPluginError = configureCustomPluginWith(userPool: { mockIdentityProvider },
                                                        initialState: initialStateError)

        let result = try await authPluginError.signUp(
            username: "user2",
            options: options)

        guard case .done = result.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(result.isSignUpComplete, "Signup result should be complete")
    }

    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked success response
    /// When: `Auth.signUp(username:password:options:)` is invoked with empty username
    /// Then: Sign up fails with error
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
    
    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked success response
    /// When: `Auth.signUp(username:password:options:)` is invoked with empty username and no password
    /// Then: Sign up fails with error
    func testSignUpPasswordlessWithEmptyUsername() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                XCTFail("Sign up API should not be called")
                return .init(codeDeliveryDetails: nil, userConfirmed: true, userSub: nil)
            }
        )

        do { _ = try await self.plugin.signUp(
            username: "",
            options: options)

        } catch {
            guard let authError = error as? AuthError else {
                XCTFail("Result should not be nil")
                return
            }
            XCTAssertEqual(authError, AuthError.validation("Username", "", "", nil))
        }
    }

    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked success response with
    /// code delivery details
    /// When: `Auth.signUp(username:password:options:)` is invoked
    /// Then: Sign up is successful with `.confirmUser` as next step
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
    
    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked success response with
    /// code delivery details
    /// When: `Auth.signUp(username:password:options:)` is invoked without a password
    /// Then: Sign up is successful with `.confirmUser` as next step
    func testSignUpPasswordlessWithUserConfirmationRequired() async throws {

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

    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked success response with
    /// with `nil` responses
    /// When: `Auth.signUp(username:password:options:)` is invoked
    /// Then: Sign up is successful with `.confirmUser` as next step
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
    
    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked success response with
    /// with `nil` responses
    /// When: `Auth.signUp(username:password:options:)` is invoked without a password
    /// Then: Sign up is successful with `.confirmUser` as next step
    func testSignUpPasswordlessNilCognitoResponse() async throws {

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

    /// Given: A response from Cognito SignUp when `userConfirmed == true` and a present `userSub`
    /// When: Invoking `signUp(username:password:options:)`
    /// Then: The caller should receive an `AuthSignUpResult` where `nextStep == .done` and
    /// `userID` is the `userSub` returned by the service.
    func testSignUpDoneWithUserSub() async throws {
        let sub = UUID().uuidString
        mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: nil,
                    userConfirmed: true,
                    userSub: sub
                )
            }
        )

        let result = try await plugin.signUp(
            username: "foo",
            password: "bar",
            options: nil
        )

        XCTAssertEqual(result.nextStep, .done)
        XCTAssertEqual(result.userID, sub)
        XCTAssertTrue(result.isSignUpComplete)
    }
    
    /// Given: A response from Cognito SignUp when `userConfirmed == true` and a present `userSub`
    /// When: Invoking `signUp(username:password:options:)` without a password
    /// Then: The caller should receive an `AuthSignUpResult` where `nextStep == .done` and
    /// `userID` is the `userSub` returned by the service.
    func testSignUpPasswordlessDoneWithUserSub() async throws {
        let sub = UUID().uuidString
        mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: nil,
                    userConfirmed: true,
                    userSub: sub
                )
            }
        )
        
        let result = try await plugin.signUp(
            username: "foo",
            password: "bar",
            options: nil
        )
        
        XCTAssertEqual(result.nextStep, .done)
        XCTAssertEqual(result.userID, sub)
        XCTAssertTrue(result.isSignUpComplete)
    }

    /// Given: A response from Cognito SignUp that includes `codeDeliveryDetails` where `userConfirmed == false`
    /// When: Invoking `signUp(username:password:options:)`
    /// Then: The caller should receive an `AuthSignUpResult` where `nextStep == .confirmUser` and
    /// the applicable associated value of that case and the `userID` both equal the `userSub` returned by the service.
    func testSignUpConfirmUserUserIDsMatch() async throws {
        let sub = UUID().uuidString
        mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: .init(
                        attributeName: "some attribute",
                        deliveryMedium: .email,
                        destination: ""
                    ),
                    userConfirmed: false,
                    userSub: sub
                )
            }
        )

        let result = try await plugin.signUp(
            username: "foo",
            password: "bar",
            options: nil
        )

        guard case .confirmUser(_, _, let userID) = result.nextStep else {
            return XCTFail("expected .confirmUser nextStep")
        }
        XCTAssertEqual(result.userID, userID)
    }
    
    /// Given: A response from Cognito SignUp that includes `codeDeliveryDetails` where `userConfirmed == false`
    /// When: Invoking `signUp(username:password:options:)` without a password
    /// Then: The caller should receive an `AuthSignUpResult` where `nextStep == .confirmUser` and
    /// the applicable associated value of that case and the `userID` both equal the `userSub` returned by the service.
    func testSignUpPasswordlessConfirmUserUserIDsMatch() async throws {
        let sub = UUID().uuidString
        mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: .init(
                        attributeName: "some attribute",
                        deliveryMedium: .email,
                        destination: ""
                    ),
                    userConfirmed: false,
                    userSub: sub
                )
            }
        )

        let result = try await plugin.signUp(
            username: "foo",
            options: nil
        )

        guard case .confirmUser(_, _, let userID) = result.nextStep else {
            return XCTFail("expected .confirmUser nextStep")
        }
        XCTAssertEqual(result.userID, userID)
    }

    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked failure response
    /// with `NotAuthorizedException`
    /// When: `Auth.signUp(username:password:options:)` is invoked
    /// Then: Sign up fails with error as `.notAuthorized`
    func testSignUpWithNotAuthorizedException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                throw AWSCognitoIdentityProvider.NotAuthorizedException()
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
    
    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked failure response
    /// with `NotAuthorizedException`
    /// When: `Auth.signUp(username:password:options:)` is invoked without a password
    /// Then: Sign up fails with error as `.notAuthorized`
    func testSignUpPasswordlessWithNotAuthorizedException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                throw AWSCognitoIdentityProvider.NotAuthorizedException()
            }
        )

        do {
            _ = try await self.plugin.signUp(
                username: "username",
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
    
    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked failure response
    /// with `InternalErrorException`
    /// When: `Auth.signUp(username:password:options:)` is invoked
    /// Then: Sign up fails with error as `.unknown`
    func testSignUpWithInternalErrorException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                throw AWSCognitoIdentityProvider.InternalErrorException()
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
    
    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked failure response
    /// with `InternalErrorException`
    /// When: `Auth.signUp(username:password:options:)` is invoked without a password
    /// Then: Sign up fails with error as `.unknown`
    func testSignUpPasswordlessWithInternalErrorException() async {

        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                throw AWSCognitoIdentityProvider.InternalErrorException()
            }
        )

        do {
            _ = try await self.plugin.signUp(
                username: "username",
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
    
    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked success response
    /// for Sign Up, Confirm Sign Up and Auto Sign In
    /// When: `Auth.signUp(username:password:options:)` is invoked followed by 
    /// `Auth.signUp(for:confirmationCode:options:)` and `Auth.autoSignIn()`
    /// Then: Sign up, Confirm Sign up and Auto sign in are complete
    func testSuccessfulSignUpAndAutoSignInEndToEnd() async throws {
        let userSub = UUID().uuidString
        self.mockIdentityProvider = MockIdentityProvider(
            mockSignUpResponse: { _ in
                return .init(
                    codeDeliveryDetails: .init(
                        attributeName: "some attribute",
                        deliveryMedium: .email,
                        destination: ""
                    ),
                    userConfirmed: false,
                    userSub: userSub
                )
            },
            mockInitiateAuthResponse: { input in
                return InitiateAuthOutput(
                    authenticationResult: .init(
                        accessToken: Defaults.validAccessToken,
                        expiresIn: 300,
                        idToken: "idToken",
                        newDeviceMetadata: nil,
                        refreshToken: "refreshToken",
                        tokenType: ""))
            },
            mockConfirmSignUpResponse: { request in
                XCTAssertNil(request.clientMetadata)
                XCTAssertNil(request.forceAliasCreation)
                return .init(session: "session")
            }
        )
        
        // sign up
        let signUpResult = try await self.plugin.signUp(
            username: "jeffb",
            options: options)

        guard case .confirmUser(_, _, let userID) = signUpResult.nextStep else {
            return XCTFail("expected .confirmUser nextStep")
        }
        XCTAssertEqual(signUpResult.userID, userID)
        XCTAssertFalse(signUpResult.isSignUpComplete)
        
        // confirm sign up
        let confirmSignUpResult = try await plugin.confirmSignUp(for: "jeffb",
                                                       confirmationCode: "123456",
                                                       options: AuthConfirmSignUpRequest.Options())
        guard case .completeAutoSignIn(let session) = confirmSignUpResult.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(confirmSignUpResult.isSignUpComplete, "Confirm Sign up result should be complete")
        XCTAssertEqual(session, "session")
        
        // auto sign in
        let autoSignInResult = try await plugin.autoSignIn()
        guard case .done = autoSignInResult.nextStep else {
            XCTFail("Result should be .done for next step")
            return
        }
        XCTAssertTrue(autoSignInResult.isSignedIn, "Signin result should be complete")
    }
    
    /// Given: Configured auth machine in `.notStarted` sign up state and a mocked failure response
    /// with different service errors
    /// When: `Auth.signUp(username:password:options:)` is invoked with/without a password
    /// Then: Sign up fails with appropriate error type returned
    func testSignUpServiceError() async {

        let errorsToTest: [(signUpOutputError: Error, cognitoError: AWSCognitoAuthError)] = [
            (AWSCognitoIdentityProvider.CodeDeliveryFailureException(), .codeDelivery),
            (AWSCognitoIdentityProvider.InvalidEmailRoleAccessPolicyException(), .emailRole),
            (AWSCognitoIdentityProvider.InvalidLambdaResponseException(), .lambda),
            (AWSCognitoIdentityProvider.InvalidParameterException(), .invalidParameter),
            (AWSCognitoIdentityProvider.InvalidPasswordException(), .invalidPassword),
            (AWSCognitoIdentityProvider.InvalidSmsRoleAccessPolicyException(), .smsRole),
            (AWSCognitoIdentityProvider.InvalidSmsRoleTrustRelationshipException(), .smsRole),
            (AWSCognitoIdentityProvider.ResourceNotFoundException(), .resourceNotFound),
            (AWSCognitoIdentityProvider.TooManyRequestsException(), .requestLimitExceeded),
            (AWSCognitoIdentityProvider.UnexpectedLambdaException(), .lambda),
            (AWSCognitoIdentityProvider.UserLambdaValidationException(), .lambda),
            (AWSCognitoIdentityProvider.UsernameExistsException(), .usernameExists),
        ]

        for errorToTest in errorsToTest {
            await validateSignUpServiceErrors(
                signUpOutputError: errorToTest.signUpOutputError,
                expectedCognitoError: errorToTest.cognitoError)
            
            await validateSignUpPasswordlessServiceErrors(
                signUpOutputError: errorToTest.signUpOutputError,
                expectedCognitoError: errorToTest.cognitoError)
        }
        
    }

    func validateSignUpServiceErrors(
        signUpOutputError: Error,
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

    func validateSignUpPasswordlessServiceErrors(
        signUpOutputError: Error,
        expectedCognitoError: AWSCognitoAuthError) async {
            self.mockIdentityProvider = MockIdentityProvider(
                mockSignUpResponse: { _ in
                    throw signUpOutputError
                }
            )

            do {
                _ = try await self.plugin.signUp(
                    username: "username",
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
