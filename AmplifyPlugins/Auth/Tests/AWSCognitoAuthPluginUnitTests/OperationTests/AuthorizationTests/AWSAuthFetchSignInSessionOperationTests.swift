//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import AWSPluginsCore

@testable import AWSPluginsTestCommon

// swiftlint:disable file_length
// swiftlint:disable type_body_length
class AWSAuthFetchSignInSessionOperationTests: XCTestCase {

    let apiTimeout = 2.0

    func configurePluginWith(authConfiguration: AuthConfiguration = Defaults.makeDefaultAuthConfigData(),
                             userPool: @escaping () throws -> CognitoUserPoolBehavior = Defaults.makeDefaultUserPool,
                             identityPool: @escaping () throws -> CognitoIdentityBehavior = Defaults.makeIdentity,
                             initialState: AuthState) -> AWSCognitoAuthPlugin {
        let plugin = AWSCognitoAuthPlugin()
        let environment = Defaults.makeDefaultAuthEnvironment(
            identityPoolFactory: identityPool,
            userPoolFactory: userPool)
        let statemachine = AuthStateMachine(resolver: AuthState.Resolver(),
                                            environment: environment,
                                            initialState: initialState)
        plugin.configure(
            authConfiguration: Defaults.makeDefaultAuthConfigData(),
            authEnvironment: environment,
            authStateMachine: statemachine,
            credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
            hubEventHandler: MockAuthHubEventBehavior())
        return plugin

    }

    /// Test signedIn session with a user signed In to userPool and identityPool enabled
    ///
    /// - Given: Given an auth plugin with signedIn state and identityPool enabled
    /// - When:
    ///    - I invoke fetchAuthSession
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = true
    ///         - aws credentails = valid values
    ///         - identity id = valid values
    ///         - cognito tokens = valid values
    ///
    func testSignInSessionWithIdentityPoolEnabled() {
        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testData))

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

        let plugin = configurePluginWith(identityPool: {
            MockIdentity(mockGetIdResponse: getId,
                         mockGetCredentialsResponse: getCredentials) },
                                         initialState: initialState)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):

                XCTAssertTrue(session.isSignedIn)

                let creds = try? (session as? AuthAWSCredentialsProvider)?.getAWSCredentials().get()
                XCTAssertNotNil(creds?.accessKey)
                XCTAssertNotNil(creds?.secretKey)

                let identityId = try? (session as? AuthCognitoIdentityProvider)?.getIdentityId().get()
                XCTAssertNotNil(identityId)

                let tokens = try? (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get()
                XCTAssertNotNil(tokens?.accessToken)
                XCTAssertNotNil(tokens?.idToken)
                XCTAssertNotNil(tokens?.refreshToken)
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    //    /// Test signedIn session with a user signed In to  identityPool
    //    ///
    //    /// - Given: Given an auth plugin with signedIn state
    //    /// - When:
    //    ///    - I invoke fetchAuthSession and mock notSignedIn for getTokens
    //    /// - Then:
    //    ///    - I should get an a valid session with the following details:
    //    ///         - isSignedIn = true
    //    ///         - aws credentails = valid values
    //    ///         - identity id = valid values
    //    ///         - cognito tokens = service error with invalidAccountTypeException error
    //    ///
    //    func testSignInToIdentityPoolSession() {
    //        mockAWSCredentials()
    //        mockIdentityId()
    //        mockAWSMobileClient.tokensMockResult = .failure(AWSMobileClientError.notSignedIn(message: "Error"))
    //        let resultExpectation = expectation(description: "Should receive a result")
    //        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
    //            defer {
    //                resultExpectation.fulfill()
    //            }
    //            switch result {
    //            case .success(let session):
    //
    //                XCTAssertTrue(session.isSignedIn)
    //
    //                let creds = try? (session as? AuthAWSCredentialsProvider)?.getAWSCredentials().get()
    //                XCTAssertNotNil(creds?.accessKey)
    //                XCTAssertNotNil(creds?.secretKey)
    //
    //                let identityId = try? (session as? AuthCognitoIdentityProvider)?.getIdentityId().get()
    //                XCTAssertNotNil(identityId)
    //
    //                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
    //                guard case .failure(let error) = tokensResult,
    //                      case .service(_, _, let underlyingError) = error,
    //                      case .invalidAccountTypeException = (underlyingError as? AWSCognitoAuthError) else {
    //                    XCTFail("Should return invalidAccountTypeException error")
    //                    return
    //                }
    //            case .failure(let error):
    //                XCTFail("Received failure with error \(error)")
    //            }
    //        }
    //        wait(for: [resultExpectation], timeout: apiTimeout)
    //    }
    //
    /// Test signedIn session with session expired
    ///
    /// - Given: Given an auth plugin with signedIn state
    /// - When:
    ///    - I invoke fetchAuthSession and mock notSignedIn for getTokens
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = true
    ///         - aws credentails = sessionExpired error
    ///         - identity id = sessionExpired error
    ///         - cognito tokens = sessionExpired error
    ///
    func testSignInSessionWithExpiredToken() {

        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens))

        let initAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            throw try InitiateAuthOutputError.notAuthorizedException(
                NotAuthorizedException.init(httpResponse: MockHttpResponse.ok))
        }

        let plugin = configurePluginWith(userPool: { MockIdentityProvider(mockInitiateAuthResponse: initAuth) }, initialState: initialState)
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):

                XCTAssertTrue(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let error) = credentialsResult, case .sessionExpired = error else {
                    XCTFail("Should return sessionExpired error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .sessionExpired = identityIdError else {
                    XCTFail("Should return sessionExpired error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let tokenError) = tokensResult,
                      case .sessionExpired = tokenError else {
                    XCTFail("Should return sessionExpired error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: 100)
    }

    /// Test signedIn session with session expired while fetching aws credentials
    ///
    /// - Given: Given an auth plugin with signedIn state
    /// - When:
    ///    - I invoke fetchAuthSession and mock notSignedIn for getAWSCredentials
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = true
    ///         - aws credentails = sessionExpired error
    ///         - identity id = sessionExpired error
    ///         - cognito tokens = sessionExpired error
    ///
    func testSignInSessionWithExpiredTokenInAWSCredentials() {

        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens))

        let initAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            return InitiateAuthOutputResponse(authenticationResult: .init(accessToken: "accessToken",
                                                                          expiresIn: 1000,
                                                                          idToken: "idToken",
                                                                          refreshToken: "refreshToke"))
        }

        let awsCredentials: MockIdentity.MockGetCredentialsResponse = { _ in
            throw try GetCredentialsForIdentityOutputError.notAuthorizedException(
                NotAuthorizedException.init(httpResponse: MockHttpResponse.ok)
            )
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockInitiateAuthResponse: initAuth) },
            identityPool: { MockIdentity(mockGetCredentialsResponse: awsCredentials) },
            initialState: initialState)

        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):

                XCTAssertTrue(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let error) = credentialsResult, case .sessionExpired = error else {
                    XCTFail("Should return sessionExpired error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .sessionExpired = identityIdError else {
                    XCTFail("Should return sessionExpired error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let tokenError) = tokensResult,
                      case .sessionExpired = tokenError else {
                    XCTFail("Should return sessionExpired error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    //
    //    /// Test signedIn session with network error for token
    //    ///
    //    /// - Given: Given an auth plugin with signedIn state
    //    /// - When:
    //    ///    - I invoke fetchAuthSession and mock netowrk error for getTokens
    //    /// - Then:
    //    ///    - I should get an a valid session with the following details:
    //    ///         - isSignedIn = true
    //    ///         - aws credentails = service error with network
    //    ///         - identity id = service error with network
    //    ///         - cognito tokens = service error with network
    //    ///
    //    func testSignInSessionWithNetworkErrorForToken() {
    //        mockAWSCredentials()
    //        mockIdentityId()
    //        let error = NSError(domain: NSURLErrorDomain, code: 1, userInfo: nil)
    //        mockAWSMobileClient.tokensMockResult = .failure(error)
    //        let resultExpectation = expectation(description: "Should receive a result")
    //        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
    //            defer {
    //                resultExpectation.fulfill()
    //            }
    //            switch result {
    //            case .success(let session):
    //
    //                XCTAssertTrue(session.isSignedIn)
    //
    //                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
    //                guard case .failure(let error) = credentialsResult,
    //                      case .service(_, _, let underlyingError) = error,
    //                      case .network = (underlyingError as? AWSCognitoAuthError) else {
    //                    XCTFail("Should return network error")
    //                    return
    //                }
    //
    //                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
    //                guard case .failure(let identityIdError) = identityIdResult,
    //                      case .service(_, _, let underlyingIdentityIdError) = identityIdError,
    //                      case .network = (underlyingIdentityIdError as? AWSCognitoAuthError) else {
    //                    XCTFail("Should return network error")
    //                    return
    //                }
    //
    //                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
    //                guard case .failure(let tokenError) = tokensResult,
    //                      case .service(_, _, let underlyingTokenError) = tokenError,
    //                      case .network = (underlyingTokenError as? AWSCognitoAuthError) else {
    //                    XCTFail("Should return network error")
    //                    return
    //                }
    //            case .failure(let error):
    //                XCTFail("Received failure with error \(error)")
    //            }
    //        }
    //        wait(for: [resultExpectation], timeout: apiTimeout)
    //    }
    //
    //    /// Test signedIn session with network error for identityId
    //    ///
    //    /// - Given: Given an auth plugin with signedIn state
    //    /// - When:
    //    ///    - I invoke fetchAuthSession and mock netowrk error for getIdentityId
    //    /// - Then:
    //    ///    - I should get an a valid session with the following details:
    //    ///         - isSignedIn = true
    //    ///         - aws credentails = service error with network
    //    ///         - identity id = service error with network
    //    ///         - cognito tokens = service error with network
    //    ///
    //    func testSignInSessionWithNetworkErrorForIdentityId() {
    //        mockAWSCredentials()
    //        mockCognitoTokens()
    //        mockIdentityId()
    //        let error = NSError(domain: NSURLErrorDomain, code: 1, userInfo: nil)
    //        mockAWSMobileClient.getIdentityIdMockResult = AWSTask(error: error)
    //        let resultExpectation = expectation(description: "Should receive a result")
    //        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
    //            defer {
    //                resultExpectation.fulfill()
    //            }
    //            switch result {
    //            case .success(let session):
    //
    //                XCTAssertTrue(session.isSignedIn)
    //
    //                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
    //                guard case .failure(let error) = credentialsResult,
    //                      case .service(_, _, let underlyingError) = error,
    //                      case .network = (underlyingError as? AWSCognitoAuthError) else {
    //                    XCTFail("Should return network error")
    //                    return
    //                }
    //
    //                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
    //                guard case .failure(let identityIdError) = identityIdResult,
    //                      case .service(_, _, let underlyingIdentityIdError) = identityIdError,
    //                      case .network = (underlyingIdentityIdError as? AWSCognitoAuthError) else {
    //                    XCTFail("Should return network error")
    //                    return
    //                }
    //
    //                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
    //                guard case .failure(let tokenError) = tokensResult,
    //                      case .service(_, _, let underlyingTokenError) = tokenError,
    //                      case .network = (underlyingTokenError as? AWSCognitoAuthError) else {
    //                    XCTFail("Should return network error")
    //                    return
    //                }
    //            case .failure(let error):
    //                XCTFail("Received failure with error \(error)")
    //            }
    //        }
    //        wait(for: [resultExpectation], timeout: apiTimeout)
    //    }
    //
    //    /// Test signedIn session with network error for aws credentials
    //    ///
    //    /// - Given: Given an auth plugin with signedIn state
    //    /// - When:
    //    ///    - I invoke fetchAuthSession and mock netowrk error for getAWSCredentials
    //    /// - Then:
    //    ///    - I should get an a valid session with the following details:
    //    ///         - isSignedIn = true
    //    ///         - aws credentails = service error with network
    //    ///         - identity id = service error with network
    //    ///         - cognito tokens = service error with network
    //    ///
    //    func testSignInSessionWithNetworkErrorForAWSCredentials() {
    //        mockAWSCredentials()
    //        mockCognitoTokens()
    //        mockIdentityId()
    //        let error = NSError(domain: NSURLErrorDomain, code: 1, userInfo: nil)
    //        mockAWSMobileClient.awsCredentialsMockResult = .failure(error)
    //        let resultExpectation = expectation(description: "Should receive a result")
    //        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
    //            defer {
    //                resultExpectation.fulfill()
    //            }
    //            switch result {
    //            case .success(let session):
    //
    //                XCTAssertTrue(session.isSignedIn)
    //
    //                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
    //                guard case .failure(let error) = credentialsResult,
    //                      case .service(_, _, let underlyingError) = error,
    //                      case .network = (underlyingError as? AWSCognitoAuthError) else {
    //                    XCTFail("Should return network error")
    //                    return
    //                }
    //
    //                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
    //                guard case .failure(let identityIdError) = identityIdResult,
    //                      case .service(_, _, let underlyingIdentityIdError) = identityIdError,
    //                      case .network = (underlyingIdentityIdError as? AWSCognitoAuthError) else {
    //                    XCTFail("Should return network error")
    //                    return
    //                }
    //
    //                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
    //                guard case .failure(let tokenError) = tokensResult,
    //                      case .service(_, _, let underlyingTokenError) = tokenError,
    //                      case .network = (underlyingTokenError as? AWSCognitoAuthError) else {
    //                    XCTFail("Should return network error")
    //                    return
    //                }
    //            case .failure(let error):
    //                XCTFail("Received failure with error \(error)")
    //            }
    //        }
    //        wait(for: [resultExpectation], timeout: apiTimeout)
    //    }
    //
    /// Test signedIn session with invalid response for tokens
    ///
    /// - Given: Given an auth plugin with signedIn state
    /// - When:
    ///    - I invoke fetchAuthSession and mock nil response for tokens
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = true
    ///         - aws credentails = unknown error
    ///         - identity id = unknown error
    ///         - cognito tokens = unknown error
    ///
    func testSignInSessionWithInvalidToken() {
        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens))

        let initAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            return InitiateAuthOutputResponse(authenticationResult: .init(accessToken: nil,
                                                                          expiresIn: 1000,
                                                                          idToken: "idToken",
                                                                          refreshToken: "refreshToke"))
        }

        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockInitiateAuthResponse: initAuth) },
            initialState: initialState)
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):

                XCTAssertTrue(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let error) = credentialsResult, case .unknown = error else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let tokenError) = tokensResult,
                      case .unknown = tokenError else {
                    XCTFail("Should return unknown error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }

    /// Test signedIn session with invalid response for aws credentials
    ///
    /// - Given: Given an auth plugin with signedIn state
    /// - When:
    ///    - I invoke fetchAuthSession and mock nil response for aws credentials
    /// - Then:
    ///    - I should get an a valid session with the following details:
    ///         - isSignedIn = true
    ///         - aws credentails = unknown error
    ///         - identity id = unknown error
    ///         - cognito tokens = unknown error
    ///
    func testSignInSessionWithInvalidAWSCredentials() {
        let initialState = AuthState.configured(
            AuthenticationState.signedIn(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataWithExpiredTokens))

        let initAuth: MockIdentityProvider.MockInitiateAuthResponse = { _ in
            return InitiateAuthOutputResponse(authenticationResult: .init(accessToken: "accessToken",
                                                                          expiresIn: 1000,
                                                                          idToken: "idToken",
                                                                          refreshToken: "refreshToke"))
        }

        let awsCredentials: MockIdentity.MockGetCredentialsResponse = { _ in
            return GetCredentialsForIdentityOutputResponse(credentials: nil, identityId: "ss")
        }
        let plugin = configurePluginWith(
            userPool: { MockIdentityProvider(mockInitiateAuthResponse: initAuth) },
            identityPool: { MockIdentity(mockGetCredentialsResponse: awsCredentials) },
            initialState: initialState)
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):

                XCTAssertTrue(session.isSignedIn)

                let credentialsResult = (session as? AuthAWSCredentialsProvider)?.getAWSCredentials()
                guard case .failure(let error) = credentialsResult, case .unknown = error else {
                    XCTFail("Should return unknown error")
                    return
                }

                let identityIdResult = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
                guard case .failure(let identityIdError) = identityIdResult,
                      case .unknown = identityIdError else {
                    XCTFail("Should return unknown error")
                    return
                }

                let tokensResult = (session as? AuthCognitoTokensProvider)?.getCognitoTokens()
                guard case .failure(let tokenError) = tokensResult,
                      case .unknown = tokenError else {
                    XCTFail("Should return unknown error")
                    return
                }
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
    }
}
