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
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class AmplifyConnectClientIntegrationTests: XCTestCase, @unchecked Sendable {

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
    }

    override func tearDown() async throws {
        await Amplify.Auth.signOut()
        try await super.tearDown()
    }

    // MARK: - Tests

    /// Test that identifyUser succeeds for a signed-in user
    ///
    /// - Given: A deployed backend and a signed-in user
    /// - When:
    ///    - identifyUser is called with a profile
    /// - Then:
    ///    - The call succeeds without throwing
    ///
    func testIdentifyUserAuthenticated() async throws {
        try await signIn()
        let client = try makeClient()

        try await client.identifyUser(
            userProfile: UserProfile(
                email: "integ-test@example.com",
                name: "Integration Test User"
            )
        )
    }

    /// Test that identifyUser succeeds for a guest (unauthenticated) caller
    ///
    /// - Given: A deployed backend with guest access enabled and no signed-in user
    /// - When:
    ///    - identifyUser is called with a profile
    /// - Then:
    ///    - The call succeeds without throwing
    ///
    func testIdentifyUserGuest() async throws {
        _ = await Amplify.Auth.signOut()
        let client = try makeClient()

        try await client.identifyUser(
            userProfile: UserProfile(email: "guest-integ-test@example.com")
        )
    }

    /// Test that identifyUser succeeds with an empty profile
    ///
    /// - Given: A deployed backend and a signed-in user
    /// - When:
    ///    - identifyUser is called with a default profile
    /// - Then:
    ///    - The call succeeds without throwing
    ///
    func testIdentifyUserMinimal() async throws {
        try await signIn()
        let client = try makeClient()

        try await client.identifyUser(userProfile: UserProfile())
    }

    /// Test that identifyUser succeeds with custom attributes and location
    ///
    /// - Given: A deployed backend and a signed-in user
    /// - When:
    ///    - identifyUser is called with custom attributes and a location
    /// - Then:
    ///    - The call succeeds without throwing
    ///
    func testIdentifyUserWithAttributesAndLocation() async throws {
        try await signIn()
        let client = try makeClient()

        try await client.identifyUser(
            userProfile: UserProfile(
                email: "custom@example.com",
                phone: "+15555550100",
                customAttributes: ["tier": "premium", "interests": "sports"],
                location: UserProfileLocation(
                    city: "Seattle",
                    country: "US",
                    postalCode: "98101",
                    region: "WA"
                )
            )
        )
    }

    /// Test that calling identifyUser twice updates the profile
    ///
    /// - Given: A deployed backend and a signed-in user
    /// - When:
    ///    - identifyUser is called twice with different attributes
    /// - Then:
    ///    - Both calls succeed without throwing
    ///
    func testIdentifyUserUpdateProfile() async throws {
        try await signIn()
        let client = try makeClient()

        try await client.identifyUser(
            userProfile: UserProfile(email: "first@example.com", name: "First")
        )

        try await client.identifyUser(
            userProfile: UserProfile(email: "updated@example.com", name: "Updated")
        )
    }

    /// Test that registerDevice and removeDevice succeed for a signed-in user
    ///
    /// - Given: A deployed backend and a signed-in user with an identified profile
    /// - When:
    ///    - registerDevice is called with a token, then removeDevice is called
    /// - Then:
    ///    - Both calls succeed without throwing
    ///
    func testRegisterAndRemoveDevice() async throws {
        try await signIn()
        let client = try makeClient()

        try await client.identifyUser(
            userProfile: UserProfile(email: "device-test@example.com")
        )
        try await client.registerDevice(token: "integ-test-device-token")
        try await client.removeDevice()
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
        let badClient = AmplifyConnectClient(
            configuration: ConnectClientConfiguration(
                region: "us-west-2",
                endpoint: "https://invalid-endpoint.example.com"
            ),
            credentialsProvider: AmplifyIntegCredentialsProvider()
        )

        do {
            try await badClient.identifyUser(userProfile: UserProfile())
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

    private func makeClient() throws -> AmplifyConnectClient {
        let configData = try TestConfigHelper.retrieve(forResource: Self.amplifyOutputs)
        let json = try JSONSerialization.jsonObject(with: configData) as! [String: Any]
        let notifications = json["notifications"] as! [String: Any]
        let amazonConnect = notifications["amazon_connect"] as! [String: Any]
        let config = ConnectClientConfiguration(
            region: amazonConnect["aws_region"] as! String,
            endpoint: amazonConnect["endpoint"] as! String
        )
        return AmplifyConnectClient(
            configuration: config,
            credentialsProvider: AmplifyIntegCredentialsProvider()
        )
    }
}

// MARK: - Credentials Bridge

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
