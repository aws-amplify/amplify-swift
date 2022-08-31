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
import AWSPluginsCore

// swiftlint:disable file_length
// swiftlint:disable type_body_length
class AWSAuthFederationToIdentityPoolTests: BaseAuthorizationTests {

    /// Test federated to identity pool
    ///
    /// - Given: Given an auth plugin with different valid states
    /// - When:
    ///    - I invoke federateToIdentityPool
    /// - Then:
    ///    - I should get a valid FederatedToken result with the following details:
    ///         - valid aws credentials
    ///         - valid identity id
    ///
    func testFederateToIdentityPool() async throws {

        let provider = AuthProvider.facebook
        let authenticationToken = "authenticationToken"
        let mockIdentityId = "identityId"

        let credentials = CognitoIdentityClientTypes.Credentials(
            accessKeyId: "accessKey",
            expiration: Date(),
            secretKey: "secretKey",
            sessionToken: "sessionKey")

        let getId: MockIdentity.MockGetIdResponse = { input in

            let logins = input.logins

            XCTAssertNotNil(input.logins)
            XCTAssert(logins?.count == 1)
            XCTAssertEqual(logins?.keys.first, provider.identityPoolProviderName)
            XCTAssertEqual(logins?.values.first, authenticationToken)

            return .init(identityId: mockIdentityId)
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { input in

            let logins = input.logins

            XCTAssertNotNil(input.logins)
            XCTAssert(logins?.count == 1)
            XCTAssertEqual(logins?.keys.first, provider.identityPoolProviderName)
            XCTAssertEqual(logins?.values.first, authenticationToken)
            XCTAssertEqual(input.identityId, mockIdentityId)

            return .init(credentials: credentials, identityId: mockIdentityId)
        }

        let statesToTest = [
            AuthState.configured(
                AuthenticationState.signedOut(.testData),
                AuthorizationState.sessionEstablished(
                    AmplifyCredentials.testDataIdentityPoolWithExpiredTokens)),
            AuthState.configured(
                AuthenticationState.notConfigured,
                AuthorizationState.sessionEstablished(
                    AmplifyCredentials.testDataIdentityPoolWithExpiredTokens)),
            AuthState.configured(
                AuthenticationState.federatedToIdentityPool,
                AuthorizationState.sessionEstablished(
                    AmplifyCredentials.testDataWithExpiredAWSCredentials)),
            AuthState.configured(
                AuthenticationState.notConfigured,
                AuthorizationState.configured),
            AuthState.configured(
                AuthenticationState.error(.testData),
                AuthorizationState.configured),
            AuthState.configured(
                AuthenticationState.signedOut(.testData),
                AuthorizationState.error(.sessionExpired)),
        ]


        for initialState in statesToTest {
            let plugin = configurePluginWith(
                identityPool: {
                    MockIdentity(
                        mockGetIdResponse: getId,
                        mockGetCredentialsResponse: getCredentials)
                },
                initialState: initialState)
            do {
                let federatedResult = try await plugin.federateToIdentityPool(withProviderToken: authenticationToken, for: provider)
                XCTAssertNotNil(federatedResult)
                XCTAssertEqual(federatedResult.credentials.sessionKey, credentials.sessionToken)
                XCTAssertEqual(federatedResult.credentials.accessKey, credentials.accessKeyId)
                XCTAssertEqual(federatedResult.credentials.secretKey, credentials.secretKey)
                XCTAssertEqual(federatedResult.identityId, mockIdentityId)
            } catch {
                XCTFail("Received failure with error \(error)")
            }
        }
    }

    /// Test multiple calls for federation to identity pool
    ///
    /// - Given: Given an auth plugin with different valid states
    /// - When:
    ///    - I invoke federateToIdentityPool multiple times
    /// - Then:
    ///    - I should get a valid FederatedToken result with the following details:
    ///         - valid aws credentials
    ///         - valid identity id
    ///
    func testMultipleFederationToIdentityPool() async throws {

        let provider = AuthProvider.facebook
        let authenticationToken = "authenticationToken"
        let mockIdentityId = "mockIdentityId"

        let credentials = CognitoIdentityClientTypes.Credentials(
            accessKeyId: "accessKey",
            expiration: Date(),
            secretKey: "secret",
            sessionToken: "session")

        let getId: MockIdentity.MockGetIdResponse = { input in

            let logins = input.logins

            XCTAssertNotNil(input.logins)
            XCTAssert(logins?.count == 1)
            XCTAssertEqual(logins?.keys.first, provider.identityPoolProviderName)
            XCTAssertEqual(logins?.values.first, authenticationToken)

            return .init(identityId: mockIdentityId)
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { input in

            let logins = input.logins

            XCTAssertNotNil(input.logins)
            XCTAssert(logins?.count == 1)
            XCTAssertEqual(logins?.keys.first, provider.identityPoolProviderName)
            XCTAssertEqual(logins?.values.first, authenticationToken)
            XCTAssertEqual(input.identityId, mockIdentityId)

            return .init(credentials: credentials, identityId: mockIdentityId)
        }

        let initialState = AuthState.configured(
            AuthenticationState.signedOut(.testData),
            AuthorizationState.sessionEstablished(
                AmplifyCredentials.testDataIdentityPoolWithExpiredTokens))
        let plugin = configurePluginWith(
            identityPool: {
                MockIdentity(
                    mockGetIdResponse: getId,
                    mockGetCredentialsResponse: getCredentials)
            },
            initialState: initialState)

        do {
            let federatedResult = try await plugin.federateToIdentityPool(withProviderToken: authenticationToken, for: provider)
            XCTAssertNotNil(federatedResult)
            XCTAssertEqual(federatedResult.credentials.sessionKey, credentials.sessionToken)
            XCTAssertEqual(federatedResult.credentials.accessKey, credentials.accessKeyId)
            XCTAssertEqual(federatedResult.credentials.secretKey, credentials.secretKey)
            XCTAssertEqual(federatedResult.credentials.expiration, credentials.expiration)
            XCTAssertEqual(federatedResult.identityId, mockIdentityId)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
        
        do {
            let secondFederatedResult = try await plugin.federateToIdentityPool(withProviderToken: authenticationToken, for: provider)
            XCTAssertNotNil(secondFederatedResult)
            XCTAssertEqual(secondFederatedResult.credentials.sessionKey, credentials.sessionToken)
            XCTAssertEqual(secondFederatedResult.credentials.accessKey, credentials.accessKeyId)
            XCTAssertEqual(secondFederatedResult.credentials.secretKey, credentials.secretKey)
            XCTAssertEqual(secondFederatedResult.credentials.expiration, credentials.expiration)
            XCTAssertEqual(secondFederatedResult.identityId, mockIdentityId)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test federated to identity pool with invalid initial states
    ///
    /// - Given: Given an auth plugin with different invalid states
    /// - When:
    ///    - I invoke federateToIdentityPool
    /// - Then:
    ///    - I should get a valid invalid state error with the following details:
    ///
    func testFederateToIdentityPoolWithInvalidInitialState() async throws {

        let provider = AuthProvider.facebook
        let authenticationToken = "authenticationToken"

        let getId: MockIdentity.MockGetIdResponse = { _ in
            XCTFail("Identity Id should not get called")
            return .init(identityId: "mockIdentityId")
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { _ in
            XCTFail("Get AWS Credentials should not get called")
            return .init(credentials: .none, identityId: "mockIdentityId")
        }

        let statesToTest = [
            AuthState.configured(
                AuthenticationState.signedOut(.testData),
                AuthorizationState.notConfigured),
            AuthState.configured(
                AuthenticationState.signedIn(.testData),
                AuthorizationState.configured)
        ]

        for initialState in statesToTest {
            let plugin = configurePluginWith(
                identityPool: {
                    MockIdentity(
                        mockGetIdResponse: getId,
                        mockGetCredentialsResponse: getCredentials)
                },
                initialState: initialState)
            do {
                _ = try await plugin.federateToIdentityPool(withProviderToken: authenticationToken, for: provider)
                XCTFail("Should not succeed")
            } catch {
                guard case AuthError.invalidState = error else {
                    XCTFail("Should receive invalid state error")
                    return
                }
            }
        }
    }

    /// Test clear federation to identity pool
    ///
    /// - Given: Given an auth plugin with federated state
    /// - When:
    ///    - I invoke clearFederationToIdentityPool
    /// - Then:
    ///    - I should get success result
    ///
    func testClearFederationToIdentityPool() async throws {

        let getId: MockIdentity.MockGetIdResponse = { input in
            XCTFail("Get ID should not get called")
            return .init(identityId: "mockIdentityId")
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { input in
            XCTFail("Get AWS Credentials should not get called")
            return .init(credentials: .none, identityId: "mockIdentityId")
        }

        let statesToTest = [
            AuthState.configured(
                AuthenticationState.federatedToIdentityPool,
                AuthorizationState.sessionEstablished(.identityPoolWithFederation(
                    federatedToken: .testData,
                    identityID: "identityId",
                    credentials: .testData))),
        ]


        for initialState in statesToTest {
            let plugin = configurePluginWith(
                identityPool: {
                    MockIdentity(
                        mockGetIdResponse: getId,
                        mockGetCredentialsResponse: getCredentials)
                },
                initialState: initialState)
            do {
                try await plugin.clearFederationToIdentityPool()
            } catch {
                XCTFail("Received failure with error \(error)")
            }
        }
    }

    /// Test clear federation to identity pool with invalid state
    ///
    /// - Given: Given an auth plugin with invalid state for clearing federation
    /// - When:
    ///    - I invoke clearFederationToIdentityPool
    /// - Then:
    ///    - I should get an invalid state error
    ///
    func testClearFederationToIdentityPoolInvalidState() async throws {

        let getId: MockIdentity.MockGetIdResponse = { input in
            XCTFail("Get ID should not get called")
            return .init(identityId: "mockIdentityId")
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { input in
            XCTFail("Get AWS Credentials should not get called")
            return .init(credentials: .none, identityId: "mockIdentityId")
        }

        let statesToTest = [
            AuthState.configured(
                AuthenticationState.federatedToIdentityPool,
                AuthorizationState.configured),
            AuthState.configured(
                AuthenticationState.configured,
                AuthorizationState.sessionEstablished(.identityPoolWithFederation(
                    federatedToken: .testData,
                    identityID: "identityId",
                    credentials: .testData)))
        ]


        for initialState in statesToTest {
            let plugin = configurePluginWith(
                identityPool: {
                    MockIdentity(
                        mockGetIdResponse: getId,
                        mockGetCredentialsResponse: getCredentials)
                },
                initialState: initialState)
            do {
                try await plugin.clearFederationToIdentityPool()
                XCTFail("Should not succeed")
            } catch {
                guard case AuthError.invalidState = error else {
                    XCTFail("Should receive invalid state error")
                    return
                }
            }
        }
    }

    /// Test fetchAuthSession when federated to identity pool with expired credentials
    ///
    /// - Given: Given an auth plugin with a federated state
    /// - When:
    ///    - I invoke fetchAuthSession
    /// - Then:
    ///    - I should get a valid Cognito result with the following details:
    ///         - isSignedIn as true
    ///         - valid aws credentials
    ///         - valid identity id
    ///         - invalid user pool tokens error
    ///
    func testFetchAuthSessionWithExpiredCredentialsWhenFederatedToIdentityPool() async throws {

        let provider = AuthProvider.facebook
        let mockIdentityId = "mockIdentityId"

        let federatedToken: FederatedToken = .testData
        let credentials = CognitoIdentityClientTypes.Credentials(
            accessKeyId: "accessKey",
            expiration: Date(),
            secretKey: "secretKey",
            sessionToken: "sessionKey")

        let cognitoAPIExpectation = expectation(description: "Cognito API gets called")
        cognitoAPIExpectation.expectedFulfillmentCount = 1

        let getId: MockIdentity.MockGetIdResponse = { input in
            XCTFail("Get ID should not get called")
            return .init(identityId: "mockIdentityId")
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { input in

            let logins = input.logins

            XCTAssertNotNil(input.logins)
            XCTAssert(logins?.count == 1)
            XCTAssertEqual(logins?.keys.first, provider.identityPoolProviderName)
            XCTAssertEqual(logins?.values.first, federatedToken.token)
            XCTAssertEqual(input.identityId, mockIdentityId)

            cognitoAPIExpectation.fulfill()

            return .init(credentials: credentials, identityId: mockIdentityId)
        }

        let initialState = AuthState.configured(
            AuthenticationState.signedOut(.testData),
            AuthorizationState.sessionEstablished(
                .identityPoolWithFederation(
                    federatedToken: federatedToken,
                    identityID: mockIdentityId,
                    credentials: .expiredTestData)))

        let plugin = configurePluginWith(
            identityPool: {
                MockIdentity(
                    mockGetIdResponse: getId,
                    mockGetCredentialsResponse: getCredentials)
            },
            initialState: initialState)
        do {
            let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
            XCTAssertTrue(session.isSignedIn)

            let creds = try? (session as? AuthAWSCredentialsProvider)?.getAWSCredentials().get()
            XCTAssertNotNil(creds?.accessKey)
            XCTAssertNotNil(creds?.secretKey)
            XCTAssertEqual(creds?.secretKey, credentials.secretKey)
            XCTAssertEqual(creds?.accessKey, credentials.accessKeyId)

            let identityId = try? (session as? AuthCognitoIdentityProvider)?.getIdentityId().get()
            XCTAssertNotNil(identityId)
            XCTAssertEqual(identityId, mockIdentityId)

            let tokens = try? (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get()
            XCTAssertNil(tokens)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
        wait(for: [cognitoAPIExpectation], timeout: apiTimeout)
    }

    /// Test fetchAuthSession when federated to identity pool with valid credentials
    ///
    /// - Given: Given an auth plugin with a federated state
    /// - When:
    ///    - I invoke fetchAuthSession
    /// - Then:
    ///    - I should get a valid Cognito result with the following details:
    ///         - isSignedIn as true
    ///         - valid aws credentials
    ///         - valid identity id
    ///         - invalid user pool tokens error
    ///
    func testFetchAuthSessionWithValidCredentialsWhenFederatedToIdentityPool() async throws {

        let mockIdentityId = "mockIdentityId"

        let federatedToken: FederatedToken = .testData
        let credentials = CognitoIdentityClientTypes.Credentials(
            accessKeyId: "accessKey",
            expiration: Date(),
            secretKey: "secretKey",
            sessionToken: "sessionKey")

        let getId: MockIdentity.MockGetIdResponse = { input in
            XCTFail("Get ID should not get called")
            return .init(identityId: "mockIdentityId")
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { input in
            XCTFail("Get AWS Credentials should not get called")
            return .init(credentials: .none, identityId: "mockIdentityId")
        }

        let initialState = AuthState.configured(
            AuthenticationState.signedOut(.testData),
            AuthorizationState.sessionEstablished(
                .identityPoolWithFederation(
                    federatedToken: federatedToken,
                    identityID: mockIdentityId,
                    credentials: .testData)))

        let plugin = configurePluginWith(
            identityPool: {
                MockIdentity(
                    mockGetIdResponse: getId,
                    mockGetCredentialsResponse: getCredentials)
            },
            initialState: initialState)
        do {
            let session = try await plugin.fetchAuthSession(options: AuthFetchSessionRequest.Options())
            XCTAssertTrue(session.isSignedIn)
            let creds = try? (session as? AuthAWSCredentialsProvider)?.getAWSCredentials().get()
            XCTAssertNotNil(creds?.accessKey)
            XCTAssertNotNil(creds?.secretKey)
            XCTAssertEqual(creds?.secretKey, credentials.secretKey)
            XCTAssertEqual(creds?.accessKey, credentials.accessKeyId)

            let identityId = try? (session as? AuthCognitoIdentityProvider)?.getIdentityId().get()
            XCTAssertNotNil(identityId)
            XCTAssertEqual(identityId, mockIdentityId)

            let tokens = try? (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get()
            XCTAssertNil(tokens)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
    }

    /// Test fetchAuthSession forceRefresh when federated to identity pool with valid credentials
    ///
    /// - Given: Given an auth plugin with a federated state with valid credentials
    /// - When:
    ///    - I invoke fetchAuthSession with force refresh flag as true
    /// - Then:
    ///    - I should get a valid Cognito result with the following details:
    ///         - isSignedIn as true
    ///         - valid aws credentials
    ///         - valid identity id
    ///         - invalid user pool tokens error
    ///
    func testFetchAuthSessionWithForceRefreshWhenFederatedToIdentityPool() async throws {

        let provider = AuthProvider.facebook
        let mockIdentityId = "mockIdentityId"

        let federatedToken: FederatedToken = .testData
        let credentials = CognitoIdentityClientTypes.Credentials(
            accessKeyId: "accessKey",
            expiration: Date(),
            secretKey: "secretKey",
            sessionToken: "sessionKey")

        let cognitoAPIExpectation = expectation(description: "Cognito API gets called")
        cognitoAPIExpectation.expectedFulfillmentCount = 1

        let getId: MockIdentity.MockGetIdResponse = { input in
            XCTFail("Get ID should not get called")
            return .init(identityId: "mockIdentityId")
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { input in

            let logins = input.logins

            XCTAssertNotNil(input.logins)
            XCTAssert(logins?.count == 1)
            XCTAssertEqual(logins?.keys.first, provider.identityPoolProviderName)
            XCTAssertEqual(logins?.values.first, federatedToken.token)
            XCTAssertEqual(input.identityId, mockIdentityId)

            cognitoAPIExpectation.fulfill()

            return .init(credentials: credentials, identityId: mockIdentityId)
        }

        let initialState = AuthState.configured(
            AuthenticationState.signedOut(.testData),
            AuthorizationState.sessionEstablished(
                .identityPoolWithFederation(
                    federatedToken: federatedToken,
                    identityID: mockIdentityId,
                    credentials: .expiredTestData)))

        let plugin = configurePluginWith(
            identityPool: {
                MockIdentity(
                    mockGetIdResponse: getId,
                    mockGetCredentialsResponse: getCredentials)
            },
            initialState: initialState)
        
        do {
            let session = try await plugin.fetchAuthSession(options: .forceRefresh())
            XCTAssertTrue(session.isSignedIn)
            let creds = try? (session as? AuthAWSCredentialsProvider)?.getAWSCredentials().get()
            XCTAssertNotNil(creds?.accessKey)
            XCTAssertNotNil(creds?.secretKey)
            XCTAssertEqual(creds?.secretKey, credentials.secretKey)
            XCTAssertEqual(creds?.accessKey, credentials.accessKeyId)

            let identityId = try? (session as? AuthCognitoIdentityProvider)?.getIdentityId().get()
            XCTAssertNotNil(identityId)
            XCTAssertEqual(identityId, mockIdentityId)

            let tokens = try? (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get()
            XCTAssertNil(tokens)
        } catch {
            XCTFail("Received failure with error \(error)")
        }
        wait(for: [cognitoAPIExpectation], timeout: apiTimeout)
    }

    /// Test federated to identity pool with developer provided identity Id
    ///
    /// - Given: Given an auth plugin with different valid states
    /// - When:
    ///    - I invoke federateToIdentityPool with developer provided identity Id
    /// - Then:
    ///    - I should get a valid FederatedToken result with the following details:
    ///         - valid aws credentials
    ///         - valid identity id
    ///
    func testFederateToIdentityPoolWithDeveloperProvidedIdentity() async throws {

        let provider = AuthProvider.facebook
        let authenticationToken = "authenticationToken"
        let mockIdentityId = "identityId"

        let credentials = CognitoIdentityClientTypes.Credentials(
            accessKeyId: "accessKey",
            expiration: Date(),
            secretKey: "secretKey",
            sessionToken: "sessionKey")

        let getId: MockIdentity.MockGetIdResponse = { input in
            XCTFail("Get ID should not get called")
            return .init(identityId: mockIdentityId)
        }

        let getCredentials: MockIdentity.MockGetCredentialsResponse = { input in

            let logins = input.logins

            XCTAssertNotNil(input.logins)
            XCTAssert(logins?.count == 1)
            XCTAssertEqual(logins?.keys.first, provider.identityPoolProviderName)
            XCTAssertEqual(logins?.values.first, authenticationToken)
            XCTAssertEqual(input.identityId, mockIdentityId)

            return .init(credentials: credentials, identityId: mockIdentityId)
        }

        let statesToTest = [
            AuthState.configured(
                AuthenticationState.signedOut(.testData),
                AuthorizationState.sessionEstablished(
                    AmplifyCredentials.testDataIdentityPoolWithExpiredTokens)),
            AuthState.configured(
                AuthenticationState.notConfigured,
                AuthorizationState.sessionEstablished(
                    AmplifyCredentials.testDataIdentityPoolWithExpiredTokens)),
            AuthState.configured(
                AuthenticationState.federatedToIdentityPool,
                AuthorizationState.sessionEstablished(
                    AmplifyCredentials.testDataWithExpiredAWSCredentials)),
            AuthState.configured(
                AuthenticationState.notConfigured,
                AuthorizationState.configured)
        ]


        for initialState in statesToTest {
            let plugin = configurePluginWith(
                identityPool: {
                    MockIdentity(
                        mockGetIdResponse: getId,
                        mockGetCredentialsResponse: getCredentials)
                },
                initialState: initialState)
            do {
                let federatedResult = try await plugin.federateToIdentityPool(
                    withProviderToken: authenticationToken,
                    for: provider,
                    options: .init(developerProvidedIdentityID: mockIdentityId))
                XCTAssertNotNil(federatedResult)
                XCTAssertEqual(federatedResult.credentials.sessionKey, credentials.sessionToken)
                XCTAssertEqual(federatedResult.credentials.accessKey, credentials.accessKeyId)
                XCTAssertEqual(federatedResult.credentials.secretKey, credentials.secretKey)
                XCTAssertEqual(federatedResult.identityId, mockIdentityId)
            } catch {
                XCTFail("Received failure with error \(error)")
            }
        }
    }

}
