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

class AWSAuthMigrationSignInOperationTests: XCTestCase {

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

    func testSignInOperationSuccess() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            return .init(authenticationResult: .init(accessToken: "accesToken",
                                                     expiresIn: 2,
                                                     idToken: "idToken",
                                                     refreshToken: "refreshToken"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success(let signUpResult):
                print("Sign In Result: \(signUpResult)")
            case .failure(let error):
                XCTAssertNil(error, "Error should not be returned")
            }
            finalCallBackExpectation.fulfill()
        }


        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperationInternalError() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.internalErrorException(.init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success:
                XCTFail("Should not produce a success result")
            case  .failure(let error):
                guard case .unknown = error else {
                    XCTFail("Should produce unknown error")
                    return
                }
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperationInvalidLambda() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.invalidLambdaResponseException(.init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success:
                XCTFail("Should not produce a success result")
            case  .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be lambda \(error)")
                    return
                }
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperationParameterException() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.invalidParameterException(.init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success:
                XCTFail("Should not produce a success result")
            case  .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .invalidParameter = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be invalid parameter \(error)")
                    return
                }
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperationSMSRoleAccessException() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.invalidSmsRoleAccessPolicyException(
                .init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success:
                XCTFail("Should not produce a success result")
            case  .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .smsRole = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Underlying error should be sms role \(error)")
                    return
                }
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperationUserPoolConfiguration() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.invalidUserPoolConfigurationException(
                .init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success:
                XCTFail("Should not produce a success result")
            case  .failure(let error):
                guard case .configuration = error else {
                    XCTFail("Should produce configuration error instead of \(error)")
                    return
                }
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperationNotAuthorized() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.notAuthorizedException(
                .init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success:
                XCTFail("Should not produce a success result")
            case  .failure(let error):
                guard case .notAuthorized = error else {
                    XCTFail("Should produce not authorized error instead of \(error)")
                    return
                }
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperatioResetPassword() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.passwordResetRequiredException(
                .init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success(let result):
                guard case .resetPassword = result.nextStep else {
                    XCTFail("Should produce reset password")
                    return
                }

            case  .failure(let error):
                XCTFail("Should not produce a error result: \(error)")
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperationResourceNotFound() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.resourceNotFoundException(
                .init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success:
                XCTFail("Should not produce a success result")
            case  .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .resourceNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce resource error instead of \(error)")
                    return
                }
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperationTooManyRequest() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.tooManyRequestsException(
                .init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success:
                XCTFail("Should not produce a success result")
            case  .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .requestLimitExceeded = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce limit exceeded error instead of \(error)")
                    return
                }
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperationUnexpectedLambda() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.unexpectedLambdaException(
                .init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success:
                XCTFail("Should not produce a success result")
            case  .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce lambda error instead of \(error)")
                    return
                }
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperationUserLambdaValidation() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.userLambdaValidationException(
                .init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success:
                XCTFail("Should not produce a success result")
            case  .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .lambda = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce lambda error instead of \(error)")
                    return
                }
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperationUserNotConfirmed() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.userNotConfirmedException(
                .init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success(let result):
                guard case .confirmSignUp = result.nextStep else {
                    XCTFail("Should produce confirm signup as next step")
                    return
                }
            case  .failure(let error):
                XCTFail("Should not produce an error result - \(error)")
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }

    func testSignInOperationUserNotFound() throws {
        let finalCallBackExpectation = expectation(description: #function)
        let initiateAuthExpectation = expectation(description: "API call should be invoked")

        let initiateAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            initiateAuthExpectation.fulfill()
            throw InitiateAuthOutputError.userNotFoundException(
                .init(message: "Error Occurred"))
        }


        mockIdentityProvider = MockIdentityProvider(mockInitiateAuthResponse: initiateAuth)
        let pluginOptions = AWSAuthSignInOptions(authFlowType: .userPassword)

        _ = plugin.signIn(username: "username",
                          password: "password", options:
                            AuthSignInRequest.Options(pluginOptions: pluginOptions)) { result in
            switch result {
            case .success:
                XCTFail("Should not produce a success result")
            case  .failure(let error):
                guard case .service(_, _, let underlyingError) = error else {
                    XCTFail("Should produce service error instead of \(error)")
                    return
                }
                guard case .userNotFound = (underlyingError as? AWSCognitoAuthError) else {
                    XCTFail("Should produce userNotFound error instead of \(error)")
                    return
                }
            }
            finalCallBackExpectation.fulfill()
        }
        wait(for: [initiateAuthExpectation,
                   finalCallBackExpectation],
             timeout: networkTimeout,
             enforceOrder: true)
    }
}
