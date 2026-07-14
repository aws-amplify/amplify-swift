//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AmplifyConnectClient
import AmplifyFoundation
import AWSCognitoAuthPlugin
import AWSPluginsCore
import Foundation
import XCTest

/// Integration tests for AmplifyConnectClient.
///
/// These tests require a deployed backend. See README.md for setup instructions.
/// Place `amplify_outputs.json` in the test bundle resources.
@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
final class AmplifyConnectClientIntegrationTests: XCTestCase {

    static let amplifyOutputs = "testconfiguration/AmplifyConnectClientIntegrationTests-amplify_outputs"
    static let credentialsResource = "testconfiguration/AmplifyConnectClientIntegrationTests-credentials"

    private static var isAmplifyConfigured = false

    override func setUp() async throws {
        try await super.setUp()

        if !Self.isAmplifyConfigured {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let data = try TestConfigHelper.retrieve(forResource: Self.amplifyOutputs)
            try Amplify.configure(with: .data(data))
            Self.isAmplifyConfigured = true
        }

        try await signIn()
    }

    override func tearDown() async throws {
        await Amplify.Auth.signOut()
        try await super.tearDown()
    }

    // MARK: - Tests

    /// Test that identifyUser succeeds with a valid authenticated request
    ///
    /// - Given: A deployed backend and a signed-in user
    /// - When:
    ///    - identifyUser is called with userId and profile
    /// - Then:
    ///    - The call succeeds without throwing
    ///
    func testIdentifyUserAuthenticated() async throws {
        let client = try await makeClient()
        let userId = try await Amplify.Auth.getCurrentUser().userId

        try await client.identifyUser(
            userId: userId,
            userProfile: UserProfile(
                email: "integ-test@example.com",
                name: "Integration Test User"
            ),
            options: IdentifyUserOptions(
                channelType: "APNS",
                platform: "iOS",
                appVersion: "1.0.0"
            )
        )
    }

    /// Test that identifyUser succeeds with minimal parameters
    ///
    /// - Given: A deployed backend and a signed-in user
    /// - When:
    ///    - identifyUser is called with only userId
    /// - Then:
    ///    - The call succeeds without throwing
    ///
    func testIdentifyUserMinimal() async throws {
        let client = try await makeClient()
        let userId = try await Amplify.Auth.getCurrentUser().userId

        try await client.identifyUser(userId: userId)
    }

    /// Test that identifyUser succeeds with custom properties
    ///
    /// - Given: A deployed backend and a signed-in user
    /// - When:
    ///    - identifyUser is called with custom properties
    /// - Then:
    ///    - The call succeeds without throwing
    ///
    func testIdentifyUserWithCustomProperties() async throws {
        let client = try await makeClient()
        let userId = try await Amplify.Auth.getCurrentUser().userId

        try await client.identifyUser(
            userId: userId,
            userProfile: UserProfile(
                email: "custom@example.com",
                customProperties: ["tier": ["premium"], "interests": ["sports", "tech"]]
            )
        )
    }

    /// Test that identifyUser succeeds with location data
    ///
    /// - Given: A deployed backend and a signed-in user
    /// - When:
    ///    - identifyUser is called with location in the profile
    /// - Then:
    ///    - The call succeeds without throwing
    ///
    func testIdentifyUserWithLocation() async throws {
        let client = try await makeClient()
        let userId = try await Amplify.Auth.getCurrentUser().userId

        try await client.identifyUser(
            userId: userId,
            userProfile: UserProfile(
                email: "location@example.com",
                location: UserProfileLocation(
                    city: "Seattle",
                    region: "WA",
                    country: "US",
                    postalCode: "98101",
                    latitude: 47.6062,
                    longitude: -122.3321
                )
            )
        )
    }

    /// Test that calling identifyUser twice for the same userId updates the profile
    ///
    /// - Given: A deployed backend and a signed-in user
    /// - When:
    ///    - identifyUser is called twice with different attributes
    /// - Then:
    ///    - Both calls succeed without throwing
    ///
    func testIdentifyUserUpdateProfile() async throws {
        let client = try await makeClient()
        let userId = try await Amplify.Auth.getCurrentUser().userId

        try await client.identifyUser(
            userId: userId,
            userProfile: UserProfile(email: "first@example.com", name: "First")
        )

        try await client.identifyUser(
            userId: userId,
            userProfile: UserProfile(email: "updated@example.com", name: "Updated")
        )
    }

    /// Test that an invalid endpoint returns a service error
    ///
    /// - Given: A client configured with an invalid endpoint
    /// - When:
    ///    - identifyUser is called
    /// - Then:
    ///    - A ConnectError is thrown
    ///
    func testInvalidEndpointThrowsError() async throws {
        let session = try await Amplify.Auth.fetchAuthSession()
        let tokensProvider = session as! AuthCognitoTokensProvider
        let tokens = try tokensProvider.getCognitoTokens().get()

        let badClient = AmplifyConnectClient(
            configuration: ConnectClientConfiguration(
                region: "us-west-2",
                endpoint: "https://invalid-endpoint.example.com"
            ),
            credentialsProvider: AmplifyIntegCredentialsProvider(),
            authTokenProvider: AmplifyIntegTokenProvider(
                idToken: tokens.idToken,
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken
            )
        )

        do {
            try await badClient.identifyUser(userId: "should-fail")
            XCTFail("Expected error for invalid endpoint")
        } catch is ConnectError {
            // Expected
        }
    }

    // MARK: - Helpers

    private func signIn() async throws {
        let session = try await Amplify.Auth.fetchAuthSession()
        if session.isSignedIn { return }

        let credentials = try TestConfigHelper.retrieveCredentials(forResource: Self.credentialsResource)
        guard let username = credentials["username"],
              let password = credentials["password"]
        else {
            throw XCTSkip("Missing username/password in credentials file. See README.md.")
        }

        _ = await Amplify.Auth.signOut()
        let result = try await Amplify.Auth.signIn(username: username, password: password)
        guard result.isSignedIn else {
            throw XCTSkip("Sign-in requires additional steps: \(result.nextStep)")
        }
    }

    private func makeClient() async throws -> AmplifyConnectClient {
        let session = try await Amplify.Auth.fetchAuthSession()
        let tokensProvider = session as! AuthCognitoTokensProvider
        let tokens = try tokensProvider.getCognitoTokens().get()

        let configData = try TestConfigHelper.retrieve(forResource: Self.amplifyOutputs)
        let json = try JSONSerialization.jsonObject(with: configData) as! [String: Any]
        let notifications = json["notifications"] as! [String: Any]
        let customerProfiles = notifications["amazon_connect_customer_profiles"] as! [String: Any]
        let config = ConnectClientConfiguration(
            region: customerProfiles["aws_region"] as! String,
            endpoint: customerProfiles["endpoint"] as! String
        )
        return AmplifyConnectClient(
            configuration: config,
            credentialsProvider: AmplifyIntegCredentialsProvider(),
            authTokenProvider: AmplifyIntegTokenProvider(
                idToken: tokens.idToken,
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken
            )
        )
    }
}

// MARK: - Auth Bridges

private struct AmplifyIntegCredentialsProvider: AmplifyFoundation.AWSCredentialsProvider {
    func resolve() async throws -> AmplifyFoundation.AWSCredentials {
        let session = try await Amplify.Auth.fetchAuthSession()
        let credentialsProvider = session as! AuthAWSCredentialsProvider
        let credentials = try credentialsProvider.getAWSCredentials().get()

        if let tempCreds = credentials as? AWSPluginsCore.AWSTemporaryCredentials {
            return BridgedTemporaryCredentials(
                accessKeyId: tempCreds.accessKeyId,
                secretAccessKey: tempCreds.secretAccessKey,
                sessionToken: tempCreds.sessionToken,
                expiration: tempCreds.expiration
            )
        }
        return BridgedCredentials(
            accessKeyId: credentials.accessKeyId,
            secretAccessKey: credentials.secretAccessKey
        )
    }
}

private struct BridgedCredentials: AmplifyFoundation.AWSCredentials {
    let accessKeyId: String
    let secretAccessKey: String
}

private struct BridgedTemporaryCredentials: AmplifyFoundation.AWSTemporaryCredentials {
    let accessKeyId: String
    let secretAccessKey: String
    let sessionToken: String
    let expiration: Date
}

private struct AmplifyIntegTokenProvider: AuthTokenProvider {
    let idToken: String
    let accessToken: String
    let refreshToken: String

    func getToken() async throws -> AuthToken? {
        IntegAuthToken(
            idToken: idToken,
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}

private struct IntegAuthToken: AuthToken {
    let idToken: String
    let accessToken: String
    let refreshToken: String
}
