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
    func testFederateToIdentityPool() {

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
            let resultExpectation = expectation(description: "Should receive a result")
            _ = plugin.federateToIdentityPool(
                withProviderToken: authenticationToken,
                for: provider) { result in
                    defer {
                        resultExpectation.fulfill()
                    }
                    switch result {
                    case .success(let federatedResult):
                        XCTAssertNotNil(federatedResult)
                        XCTAssertEqual(federatedResult.credentials.sessionKey, credentials.sessionToken)
                        XCTAssertEqual(federatedResult.credentials.accessKey, credentials.accessKeyId)
                        XCTAssertEqual(federatedResult.credentials.secretKey, credentials.secretKey)
                        XCTAssertEqual(federatedResult.identityId, mockIdentityId)

                    case .failure(let error):
                        XCTFail("Received failure with error \(error)")
                    }
                }
            wait(for: [resultExpectation], timeout: apiTimeout)
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
    func testMultipleFederationToIdentityPool() {

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

        let firstResultExpectation = expectation(description: "Should receive a result")
        _ = plugin.federateToIdentityPool(
            withProviderToken: authenticationToken,
            for: provider) { result in
                defer {
                    firstResultExpectation.fulfill()
                }
                switch result {
                case .success(let federatedResult):
                    XCTAssertNotNil(federatedResult)
                    XCTAssertEqual(federatedResult.credentials.sessionKey, credentials.sessionToken)
                    XCTAssertEqual(federatedResult.credentials.accessKey, credentials.accessKeyId)
                    XCTAssertEqual(federatedResult.credentials.secretKey, credentials.secretKey)
                    XCTAssertEqual(federatedResult.credentials.expiration, credentials.expiration)
                    XCTAssertEqual(federatedResult.identityId, mockIdentityId)

                case .failure(let error):
                    XCTFail("Received failure with error \(error)")
                }
            }
        wait(for: [firstResultExpectation], timeout: apiTimeout)

        let secondResultExpectation = expectation(description: "Should receive a result")
        _ = plugin.federateToIdentityPool(
            withProviderToken: authenticationToken,
            for: provider) { result in
                defer {
                    secondResultExpectation.fulfill()
                }
                switch result {
                case .success(let federatedResult):
                    XCTAssertNotNil(federatedResult)
                    XCTAssertEqual(federatedResult.credentials.sessionKey, credentials.sessionToken)
                    XCTAssertEqual(federatedResult.credentials.accessKey, credentials.accessKeyId)
                    XCTAssertEqual(federatedResult.credentials.secretKey, credentials.secretKey)
                    XCTAssertEqual(federatedResult.credentials.expiration, credentials.expiration)
                    XCTAssertEqual(federatedResult.identityId, mockIdentityId)

                case .failure(let error):
                    XCTFail("Received failure with error \(error)")
                }
            }
        wait(for: [secondResultExpectation], timeout: apiTimeout)
    }

    /// Test federated to identity pool with invalid initial states
    ///
    /// - Given: Given an auth plugin with different invalid states
    /// - When:
    ///    - I invoke federateToIdentityPool
    /// - Then:
    ///    - I should get a valid invalid state error with the following details:
    ///
    func testFederateToIdentityPoolWithInvalidInitialState() {

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
            let resultExpectation = expectation(description: "Should receive a result")
            _ = plugin.federateToIdentityPool(
                withProviderToken: authenticationToken,
                for: provider) { result in
                    defer {
                        resultExpectation.fulfill()
                    }
                    switch result {
                    case .success:
                        XCTFail("Should not succeed")
                    case .failure(let error):
                        guard case .invalidState = error else {
                            XCTFail("Should receive invalid state error")
                            return
                        }
                    }
                }
            wait(for: [resultExpectation], timeout: apiTimeout)
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
    func testClearFederationToIdentityPool() {

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
            let resultExpectation = expectation(description: "Should receive a result")
            _ = plugin.clearFederationToIdentityPool() { result in
                defer {
                    resultExpectation.fulfill()
                }
                switch result {
                case .success:
                    break
                case .failure(let error):
                    XCTFail("Received failure with error \(error)")
                }
            }
            wait(for: [resultExpectation], timeout: apiTimeout)
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
    func testClearFederationToIdentityPoolInvalidState() {

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
            let resultExpectation = expectation(description: "Should receive a result")
            _ = plugin.clearFederationToIdentityPool() { result in
                defer {
                    resultExpectation.fulfill()
                }
                switch result {
                case .success:
                    XCTFail("Should not succeed")
                case .failure(let error):
                    guard case .invalidState = error else {
                        XCTFail("Should receive invalid state error")
                        return
                    }
                }
            }
            wait(for: [resultExpectation], timeout: apiTimeout)
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
    func testFetchAuthSessionWithExpiredCredentialsWhenFederatedToIdentityPool() {

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
                XCTAssertEqual(creds?.secretKey, credentials.secretKey)
                XCTAssertEqual(creds?.accessKey, credentials.accessKeyId)

                let identityId = try? (session as? AuthCognitoIdentityProvider)?.getIdentityId().get()
                XCTAssertNotNil(identityId)
                XCTAssertEqual(identityId, mockIdentityId)

                let tokens = try? (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get()
                XCTAssertNil(tokens)
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation, cognitoAPIExpectation], timeout: apiTimeout)
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
    func testFetchAuthSessionWithValidCredentialsWhenFederatedToIdentityPool() {

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
                XCTAssertEqual(creds?.secretKey, credentials.secretKey)
                XCTAssertEqual(creds?.accessKey, credentials.accessKeyId)

                let identityId = try? (session as? AuthCognitoIdentityProvider)?.getIdentityId().get()
                XCTAssertNotNil(identityId)
                XCTAssertEqual(identityId, mockIdentityId)

                let tokens = try? (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get()
                XCTAssertNil(tokens)
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation], timeout: apiTimeout)
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
    func testFetchAuthSessionWithForceRefreshWhenFederatedToIdentityPool() {

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
        let resultExpectation = expectation(description: "Should receive a result")
        _ = plugin.fetchAuthSession(options: .forceRefresh()) { result in
            defer {
                resultExpectation.fulfill()
            }
            switch result {
            case .success(let session):

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
            case .failure(let error):
                XCTFail("Received failure with error \(error)")
            }
        }
        wait(for: [resultExpectation, cognitoAPIExpectation], timeout: apiTimeout)
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
    func testFederateToIdentityPoolWithDeveloperProvidedIdentity() {

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
            let resultExpectation = expectation(description: "Should receive a result")
            _ = plugin.federateToIdentityPool(
                withProviderToken: authenticationToken,
                for: provider,
                options: .init(developerProvidedIdentityID: mockIdentityId)) { result in
                    defer {
                        resultExpectation.fulfill()
                    }
                    switch result {
                    case .success(let federatedResult):
                        XCTAssertNotNil(federatedResult)
                        XCTAssertEqual(federatedResult.credentials.sessionKey, credentials.sessionToken)
                        XCTAssertEqual(federatedResult.credentials.accessKey, credentials.accessKeyId)
                        XCTAssertEqual(federatedResult.credentials.secretKey, credentials.secretKey)
                        XCTAssertEqual(federatedResult.identityId, mockIdentityId)

                    case .failure(let error):
                        XCTFail("Received failure with error \(error)")
                    }
                }
            wait(for: [resultExpectation], timeout: apiTimeout)
        }
    }

}
