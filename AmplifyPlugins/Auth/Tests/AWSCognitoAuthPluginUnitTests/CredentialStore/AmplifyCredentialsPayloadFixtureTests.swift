//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import Foundation
import XCTest
@_spi(KeychainStore) import AWSPluginsCore
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The frozen `AmplifyCredentials` payloads, one per case, in
/// `AWSCognitoAuthPluginUnitTests/TestResources/amplifyCredentials/<case name>.payload.json`. The `.payload`
/// suffix keeps the files clear of the repository's `*credentials.json` ignore rule.
///
/// Each file holds the exact bytes this plugin's `JSONEncoder` wrote for fixed values, which is the
/// payload the Cognito client's session record carries base64-encoded in `credentials`. Released plugins
/// decode that payload with this plugin's synthesized `Codable`, so the files are a contract: **any
/// encoder that writes session records** (the engine's fork of `AmplifyCredentials`) must
/// produce bytes that decode to the same values here, and must decode these files itself. Never edit a
/// file; add a new one if the format ever grows.
enum AmplifyCredentialsPayloadFixtures {

    /// The directory, inside this test target's resources, that holds the fixtures.
    static let subdirectory = "TestResources/amplifyCredentials"

    /// The case names, which are also the file names.
    static let caseNames = [
        "userPoolOnly",
        "userPoolAndIdentityPool",
        "identityPoolOnly",
        "identityPoolWithFederation",
        "noCredentials"
    ]

    static func data(_ caseName: String) throws -> Data {
        guard let url = Bundle.authCognitoTestBundle().url(
            forResource: caseName,
            withExtension: "payload.json",
            subdirectory: subdirectory
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }

    /// The values the fixtures were written from.
    static func expected(_ caseName: String) -> AmplifyCredentials? {
        switch caseName {
        case "userPoolOnly":
            return .userPoolOnly(signedInData: signedInData(method: .apiBased(.userSRP), device: .noData))
        case "userPoolAndIdentityPool":
            return .userPoolAndIdentityPool(
                signedInData: signedInData(
                    method: .apiBased(.userPassword),
                    device: .metadata(.init(
                        deviceKey: "fixture-device-key",
                        deviceGroupKey: "fixture-device-group-key",
                        deviceSecret: "fixture-device-secret"
                    ))
                ),
                identityID: "us-east-1:fixture-identity-id",
                credentials: awsCredentials
            )
        case "identityPoolOnly":
            return .identityPoolOnly(identityID: "us-east-1:fixture-guest-identity-id", credentials: awsCredentials)
        case "identityPoolWithFederation":
            return .identityPoolWithFederation(
                federatedToken: FederatedToken(token: "fixture-federated-token", provider: .facebook),
                identityID: "us-east-1:fixture-federated-identity-id",
                credentials: awsCredentials
            )
        case "noCredentials":
            return .noCredentials
        default:
            return nil
        }
    }

    /// The id and access token in the fixtures: claims `sub` fixture-sub, `username` fixture-user,
    /// `exp` 2000000000.
    static let token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmaXh0dXJlLXN1YiIsInVzZXJuYW1lIjoiZml4dHVyZS11c2VyIiwiaWF0Ijoi" +
        "MTcwMDAwMDAwMCIsImV4cCI6IjIwMDAwMDAwMDAifQ.SnIqbKQB0G1_hgfw3bmkJXzH8KNo1i8w6sQyxwP50kw"

    private static let awsCredentials = EngineAWSCredentials(
        accessKeyId: "fixture-access-key-id",
        secretAccessKey: "fixture-secret-access-key",
        sessionToken: "fixture-session-token",
        expiration: Date(timeIntervalSince1970: 2_000_000_000)
    )

    private static func signedInData(method: SignInMethod, device: DeviceMetadata) -> SignedInData {
        SignedInData(
            signedInDate: Date(timeIntervalSince1970: 1_790_000_000),
            signInMethod: method,
            deviceMetadata: device,
            cognitoUserPoolTokens: EngineUserPoolTokens(
                idToken: token,
                accessToken: token,
                refreshToken: "fixture-refresh-token",
                expiresIn: nil
            )
        )
    }
}

/// Decodes the frozen payload fixtures with the plugin's own types, and reads each through the plugin's
/// fallback to the Cognito client's default-session record.
class AmplifyCredentialsPayloadFixtureTests: XCTestCase {

    private let authConfiguration = AuthConfiguration.userPoolsAndIdentityPools(
        UserPoolConfigurationData(poolId: "us-east-1_Pool", clientId: "client", region: "us-east-1"),
        IdentityPoolConfigurationData(poolId: "us-east-1:identity-pool", region: "us-east-1")
    )

    /// Test that every frozen payload still decodes to the values it was written from
    ///
    /// - Given: The five frozen `AmplifyCredentials` payload files
    /// - When:
    ///    - Each is decoded with the plugin's `JSONDecoder` and synthesized `Codable`
    /// - Then:
    ///    - Each equals the value it was written from, including dates, device metadata, the sign-in method
    ///      and the federated provider
    ///
    func testEveryFrozenPayload_decodesToItsValues() throws {
        for caseName in AmplifyCredentialsPayloadFixtures.caseNames {
            let data = try AmplifyCredentialsPayloadFixtures.data(caseName)
            let decoded = try JSONDecoder().decode(AmplifyCredentials.self, from: data)
            XCTAssertEqual(decoded, AmplifyCredentialsPayloadFixtures.expected(caseName), caseName)
        }
    }

    /// Test that the fixtures still describe what this plugin writes
    ///
    /// - Given: The values each fixture was written from
    /// - When:
    ///    - Each is encoded with the plugin's encoder and decoded again, and each fixture is re-encoded
    /// - Then:
    ///    - Both round-trips give the same value, and a signed-in fixture's top-level case key is its file
    ///      name, so the contract describes the format actually written, not an old one
    ///
    func testFixtures_matchWhatThePluginWrites() throws {
        for caseName in AmplifyCredentialsPayloadFixtures.caseNames {
            let expected = try XCTUnwrap(AmplifyCredentialsPayloadFixtures.expected(caseName), caseName)
            let encoded = try JSONEncoder().encode(expected)
            XCTAssertEqual(try JSONDecoder().decode(AmplifyCredentials.self, from: encoded), expected, caseName)

            let fixture = try AmplifyCredentialsPayloadFixtures.data(caseName)
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: fixture) as? [String: Any], caseName)
            XCTAssertEqual(Array(object.keys), [caseName])
        }
    }

    /// Test that the plugin signs in from each frozen payload carried in a client record
    ///
    /// - Given: For each fixture, a version-1 client default-session record, written by the client's record
    ///   store, whose `credentials` are exactly the fixture's bytes
    /// - When:
    ///    - The plugin retrieves its credentials
    /// - Then:
    ///    - Each signed-in fixture is returned as its values; the `noCredentials` fixture reads as no session
    ///
    func testEveryFrozenPayload_isReadFromAClientRecord() throws {
        let kinds: [String: SessionKind] = [
            "userPoolOnly": .userPoolOnly,
            "userPoolAndIdentityPool": .userPoolAndIdentityPool,
            "identityPoolOnly": .guest,
            "identityPoolWithFederation": .federated,
            "noCredentials": .userPoolOnly
        ]
        for caseName in AmplifyCredentialsPayloadFixtures.caseNames {
            let keychain = InMemoryKeychain()
            let record = try SessionRecord(
                label: nil,
                username: nil,
                kind: XCTUnwrap(kinds[caseName]),
                credentials: AmplifyCredentialsPayloadFixtures.data(caseName)
            )
            let clientStore = SessionRecordStore(
                namespace: SessionStorageNamespace(
                    pools: .userPoolAndIdentityPool(userPoolId: "us-east-1_Pool", identityPoolId: "us-east-1:identity-pool"),
                    accessGroup: nil
                ),
                keychain: keychain.store(service: SessionRecordStore.unsharedService)
            )
            XCTAssertTrue(try clientStore.write(record, for: .default, expecting: nil).didCommit, caseName)
            let store = AWSCognitoAuthCredentialStore(
                authConfiguration: authConfiguration,
                keychain: InMemoryPluginKeychainStore(keychain: keychain)
            )

            if caseName == "noCredentials" {
                XCTAssertThrowsError(try store.retrieveCredential(), caseName) { error in
                    XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
                }
            } else {
                XCTAssertEqual(try store.retrieveCredential(), AmplifyCredentialsPayloadFixtures.expected(caseName), caseName)
            }
        }
    }
}
