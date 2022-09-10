//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
import ClientRuntime

import AWSCognitoIdentityProvider
import AWSCognitoIdentity

class AWSAuthMigrationSignInTaskTests: XCTestCase {

    let networkTimeout = TimeInterval(5)
    var mockIdentityProvider: CognitoUserPoolBehavior!
    let initialState = AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured)
    var plugin: AWSCognitoAuthPlugin!

    override func setUp() {
        super.setUp()
        plugin = AWSCognitoAuthPlugin()

        let getId: MockIdentity.MockGetIdResponse = { _ in
            return .init(identityId: "mockIdentityId")
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { _ in
            let credentials = CognitoIdentityClientTypes.Credentials(accessKeyId: "accessKey",
                                                                     expiration: Date(),
                                                                     secretKey: "secret",
                                                                     sessionToken: "session")
            return .init(credentials: credentials, identityId: "responseIdentityID")
        }

        let mockIdentity = MockIdentity(
            mockGetIdResponse: getId,
            mockGetCredentialsResponse: getCredentials)

        let environment = Defaults.makeDefaultAuthEnvironment(
            identityPoolFactory: { mockIdentity },
            userPoolFactory: { self.mockIdentityProvider })

        let statemachine = Defaults.makeDefaultAuthStateMachine(
            initialState: initialState,
            identityPoolFactory: { mockIdentity },
            userPoolFactory: { self.mockIdentityProvider })

        plugin?.configure(
            authConfiguration: Defaults.makeDefaultAuthConfigData(),
            authEnvironment: environment,
            authStateMachine: statemachine,
            credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
            hubEventHandler: MockAuthHubEventBehavior())
    }

    override func tearDown() {
        plugin = nil
    }

    func testSignInOperationSuccess() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            return .init(authenticationResult: .init(accessToken: Defaults.validAccessToken,
                                                     expiresIn: 2,
                                                     idToken: "idToken",
                                                     refreshToken: "refreshToken"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            print("Sign In Result: \(result)")
        } catch {
            XCTFail("Error should not be returned \(error)")
        }

        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperationInternalError() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.internalErrorException(.init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            XCTFail("Should not produce a success result")

        } catch {
            guard case AuthError.unknown = error else {
                XCTFail("Should produce unknown error")
                return
            }
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperationInvalidLambda() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.invalidLambdaResponseException(.init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            XCTFail("Should not produce a success result")

        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be lambda \(error)")
                return
            }
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperationParameterException() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.invalidParameterException(.init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            XCTFail("Should not produce a success result")

        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be invalid parameter \(error)")
                return
            }
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperationSMSRoleAccessException() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.invalidSmsRoleAccessPolicyException(
                .init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            XCTFail("Should not produce a success result")

        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Underlying error should be sms role \(error)")
                return
            }
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperationUserPoolConfiguration() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.invalidUserPoolConfigurationException(
                .init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            XCTFail("Should not produce a success result")

        } catch {
            guard case AuthError.configuration = error else {
                XCTFail("Should produce configuration error instead of \(error)")
                return
            }
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperationNotAuthorized() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.notAuthorizedException(
                .init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            XCTFail("Should not produce a success result")

        } catch {
            guard case AuthError.notAuthorized = error else {
                XCTFail("Should produce not authorized error instead of \(error)")
                return
            }
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperatioResetPassword() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.passwordResetRequiredException(
                .init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            guard case .resetPassword = result.nextStep else {
                XCTFail("Should produce reset password")
                return
            }
        } catch {
            XCTFail("Should not produce a error result: \(error)")
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperationResourceNotFound() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.resourceNotFoundException(
                .init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            XCTFail("Should not produce a success result")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce resource error instead of \(error)")
                return
            }
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperationTooManyRequest() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.tooManyRequestsException(
                .init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            XCTFail("Should not produce a success result")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce limit exceeded error instead of \(error)")
                return
            }
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperationUnexpectedLambda() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.unexpectedLambdaException(
                .init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            XCTFail("Should not produce a success result")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce lambda error instead of \(error)")
                return
            }
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperationUserLambdaValidation() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.userLambdaValidationException(
                .init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            XCTFail("Should not produce a success result")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce lambda error instead of \(error)")
                return
            }
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperationUserNotConfirmed() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.userNotConfirmedException(
                .init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            let result = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            guard case .confirmSignUp = result.nextStep else {
                XCTFail("Should produce confirm signup as next step")
                return
            }
        } catch {
            XCTFail("Should not produce an error result - \(error)")
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }

    func testSignInOperationUserNotFound() async throws {
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.userNotFoundException(
                .init(message: "Error Occurred"))
        }

        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)
        do {
            _ = try await plugin.signIn(username: "username", password: "password", options: AuthSignInRequest.Options(pluginOptions: pluginOptions))
            XCTFail("Should not produce a success result")
        } catch {
            guard case AuthError.service(_, _, let underlyingError) = error else {
                XCTFail("Should produce service error instead of \(error)")
                return
            }
            guard case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                XCTFail("Should produce userNotFound error instead of \(error)")
                return
            }
        }
        wait(for: [initiateAuthExpectation], timeout: networkTimeout)
    }
}
