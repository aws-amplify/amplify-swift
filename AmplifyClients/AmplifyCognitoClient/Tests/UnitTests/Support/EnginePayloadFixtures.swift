//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The frozen `AmplifyCredentials` payloads, one per case, read in place from the plugin's test resources
/// (`AWSCognitoAuthPluginUnitTests/TestResources/amplifyCredentials/<case>.payload.json`), the same way the
/// configuration parity test reads the configuration goldens. The released plugin decodes these bytes, so they
/// are the contract the client's payloads keep. Never edited, never copied.
enum EnginePayloadFixtures {

    static let caseNames = [
        "userPoolOnly",
        "userPoolAndIdentityPool",
        "identityPoolOnly",
        "identityPoolWithFederation",
        "noCredentials"
    ]

    static func url(_ caseName: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Support
            .deletingLastPathComponent() // UnitTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // AmplifyCognitoClient
            .deletingLastPathComponent() // AmplifyClients
            .deletingLastPathComponent() // repository root
            .appendingPathComponent("AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests/TestResources/amplifyCredentials")
            .appendingPathComponent("\(caseName).payload.json")
    }

    static func data(_ caseName: String) throws -> Data {
        try Data(contentsOf: url(caseName))
    }

    /// What each fixture holds, as the plugin's `AmplifyCredentialsPayloadFixtures` wrote it: the token's
    /// claims are `sub` `fixture-sub` and `username` `fixture-user`.
    static func expectedSummary(_ caseName: String) -> CredentialSummary? {
        switch caseName {
        case "userPoolOnly":
            return CredentialSummary(kind: .userPoolOnly, username: "fixture-user", userId: "fixture-sub")
        case "userPoolAndIdentityPool":
            return CredentialSummary(
                kind: .userPoolAndIdentityPool,
                username: "fixture-user",
                userId: "fixture-sub",
                identityId: "us-east-1:fixture-identity-id"
            )
        case "identityPoolOnly":
            return CredentialSummary(kind: .guest, username: nil, userId: nil, identityId: "us-east-1:fixture-guest-identity-id")
        case "identityPoolWithFederation":
            return CredentialSummary(
                kind: .federated,
                username: nil,
                userId: nil,
                identityId: "us-east-1:fixture-federated-identity-id"
            )
        case "noCredentials":
            return CredentialSummary(kind: .signedOut, username: nil, userId: nil)
        default:
            return nil
        }
    }

    /// The id and access token in the fixtures, and their expiry (the `exp` claim), which is also the AWS
    /// credentials' expiration.
    static let token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmaXh0dXJlLXN1YiIsInVzZXJuYW1lIjoiZml4dHVyZS11c2VyIiwiaWF0Ijoi" +
        "MTcwMDAwMDAwMCIsImV4cCI6IjIwMDAwMDAwMDAifQ.SnIqbKQB0G1_hgfw3bmkJXzH8KNo1i8w6sQyxwP50kw"
    static let refreshToken = "fixture-refresh-token"
    static let expiry = Date(timeIntervalSince1970: 2_000_000_000)

    static let awsCredentials = CognitoAWSCredentials(
        accessKeyId: "fixture-access-key-id",
        secretAccessKey: "fixture-secret-access-key",
        sessionToken: "fixture-session-token",
        expiration: expiry
    )

    /// The fixture decoded with the plugin store's coder.
    static func credentials(_ caseName: String) throws -> AmplifyCredentials {
        try JSONDecoder().decode(AmplifyCredentials.self, from: data(caseName))
    }
}
