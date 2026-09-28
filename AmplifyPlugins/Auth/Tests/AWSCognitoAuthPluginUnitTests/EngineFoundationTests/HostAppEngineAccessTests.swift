//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The plugin-internal helpers the AuthHostApp integration target goes through, because it cannot name the
/// engine's `package` types (`Support/HostAppAccess/HostAppEngineAccess.swift`).
final class HostAppEngineAccessTests: XCTestCase {

    /// Every `AmplifyCredentials` case, with each signed-in shape.
    static func everyCredential() -> [(String, AmplifyCredentials)] {
        let federated = FederatedToken(token: "federated-token", provider: .facebook)
        return [
            ("userPoolOnly", .userPoolOnly(signedInData: .testData)),
            ("userPoolOnly-hostedUI", .userPoolOnly(signedInData: .hostedUISignInData)),
            ("identityPoolOnly", .identityPoolOnly(identityID: "identity", credentials: .testData)),
            (
                "identityPoolWithFederation",
                .identityPoolWithFederation(federatedToken: federated, identityID: "identity", credentials: .testData)
            ),
            (
                "userPoolAndIdentityPool",
                .userPoolAndIdentityPool(signedInData: .testData, identityID: "identity", credentials: .testData)
            ),
            ("noCredentials", .noCredentials)
        ]
    }

    /// Test that the host-app credentials are `AmplifyCredentials`, case for case
    ///
    /// - Given: Every `AmplifyCredentials` case
    /// - When:
    ///    - Each is converted to `HostAppCredentials` and back
    /// - Then:
    ///    - The round trip gives the same value, the case and payloads are the same, and two different
    ///      values stay different
    ///
    func testCredentialsRoundTripCaseForCase() {
        let values = Self.everyCredential()
        for (label, credentials) in values {
            let hostApp = HostAppCredentials(credentials)
            XCTAssertEqual(AmplifyCredentials(hostApp), credentials, label)
            XCTAssertEqual(HostAppCredentials(AmplifyCredentials(hostApp)), hostApp, label)
            switch (credentials, hostApp) {
            case (.userPoolOnly(let engine), .userPoolOnly(let view)):
                XCTAssertEqual(view.signedInData, engine, label)
            case (.identityPoolOnly(let engineID, let engineCredentials), .identityPoolOnly(let id, let credentials)):
                XCTAssertEqual(id, engineID, label)
                XCTAssertEqual(credentials, engineCredentials, label)
            case (
                .identityPoolWithFederation(let engineToken, let engineID, let engineCredentials),
                .identityPoolWithFederation(let token, let id, let credentials)
            ):
                XCTAssertEqual(token, engineToken, label)
                XCTAssertEqual(id, engineID, label)
                XCTAssertEqual(credentials, engineCredentials, label)
            case (
                .userPoolAndIdentityPool(let engineData, let engineID, let engineCredentials),
                .userPoolAndIdentityPool(let view, let id, let credentials)
            ):
                XCTAssertEqual(view.signedInData, engineData, label)
                XCTAssertEqual(id, engineID, label)
                XCTAssertEqual(credentials, engineCredentials, label)
            case (.noCredentials, .noCredentials):
                break
            default:
                XCTFail("\(label): \(credentials) became \(hostApp)")
            }
        }
        for (lhsLabel, lhs) in values {
            for (rhsLabel, rhs) in values {
                XCTAssertEqual(HostAppCredentials(lhs) == HostAppCredentials(rhs), lhs == rhs, "\(lhsLabel) == \(rhsLabel)")
            }
        }
    }

    /// Test that the host-app signed-in data reads and builds `SignedInData`
    ///
    /// - Given: A signed-in value for each sign-in method
    /// - When:
    ///    - Its members are read through `HostAppSignedInData`, and a value is built with the host-app
    ///      initializer and `SignInMethod(apiBased:)`
    /// - Then:
    ///    - The members are the engine value's, and the built value equals the one `SignedInData.init`
    ///      builds from the same inputs
    ///
    func testSignedInDataMembersAndInit() {
        for data in [SignedInData.testData, .hostedUISignInData] {
            let view = HostAppSignedInData(data)
            XCTAssertEqual(view.signedInDate, data.signedInDate)
            XCTAssertEqual(view.signInMethod, data.signInMethod)
            XCTAssertEqual(view.cognitoUserPoolTokens, data.cognitoUserPoolTokens)
        }
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let tokens = EngineUserPoolTokens.testData
        for flow in [AuthFlowType.userSRP, .userPassword, .customWithSRP, .customWithoutSRP] {
            let built = HostAppSignedInData(
                signedInDate: date,
                signInMethod: .init(apiBased: flow),
                cognitoUserPoolTokens: tokens
            )
            let expected = SignedInData(
                signedInDate: date,
                signInMethod: .apiBased(EngineAuthFlowType(flow)),
                cognitoUserPoolTokens: tokens
            )
            XCTAssertEqual(built.signedInData, expected, "\(flow)")
        }
    }

    /// Test that the host-app configuration factories build the engine's values
    ///
    /// - Given: User pool and identity pool inputs, with and without the optional members
    /// - When:
    ///    - The values are built through `HostAppConfiguration`
    /// - Then:
    ///    - Each equals the value built with the engine's own initializer or case
    ///
    func testConfigurationFactories() {
        let userPool = HostAppConfiguration.userPool(poolId: "pool", clientId: "client", region: "us-east-1")
        XCTAssertEqual(userPool, UserPoolConfigurationData(poolId: "pool", clientId: "client", region: "us-east-1"))
        let full = HostAppConfiguration.userPool(
            poolId: "pool",
            clientId: "client",
            region: "us-east-1",
            clientSecret: "secret",
            pinpointAppId: "pinpoint"
        )
        XCTAssertEqual(
            full,
            UserPoolConfigurationData(
                poolId: "pool",
                clientId: "client",
                region: "us-east-1",
                clientSecret: "secret",
                pinpointAppId: "pinpoint"
            )
        )
        let identityPool = HostAppConfiguration.identityPool(poolId: "identity", region: "us-east-1")
        XCTAssertEqual(identityPool, IdentityPoolConfigurationData(poolId: "identity", region: "us-east-1"))

        XCTAssertEqual(HostAppConfiguration.userPools(full), AuthConfiguration.userPools(full))
        XCTAssertEqual(HostAppConfiguration.identityPools(identityPool), AuthConfiguration.identityPools(identityPool))
        XCTAssertEqual(
            HostAppConfiguration.userPoolsAndIdentityPools(full, identityPool),
            AuthConfiguration.userPoolsAndIdentityPools(full, identityPool)
        )
    }

    /// Test that the host-app credential store is the engine store
    ///
    /// - Given: An engine credential store over an in-memory keychain, and the host-app store wrapping it
    /// - When:
    ///    - Every `AmplifyCredentials` case is saved through one and read through the other
    /// - Then:
    ///    - Each read gives the value the store keeps for what was saved (its JSON round trip, which drops
    ///      a hosted-UI `authProvider`), in both directions
    ///
    func testCredentialStoreForwardsToTheEngineStore() throws {
        let configuration = AuthConfiguration.userPoolsAndIdentityPools(
            UserPoolConfigurationData(poolId: "us-east-1_Pool", clientId: "client", region: "us-east-1"),
            IdentityPoolConfigurationData(poolId: "us-east-1:identity-pool", region: "us-east-1")
        )
        let engineStore = AWSCognitoAuthCredentialStore(
            authConfiguration: configuration,
            keychain: InMemoryPluginKeychainStore(keychain: InMemoryKeychain())
        )
        let hostAppStore = HostAppCredentialStore(engineStore)
        for (label, credentials) in Self.everyCredential() {
            let stored = try JSONDecoder().decode(AmplifyCredentials.self, from: JSONEncoder().encode(credentials))
            try hostAppStore.saveCredential(credentials)
            XCTAssertEqual(try engineStore.retrieveCredential(), stored, label)
            try engineStore.saveCredential(.noCredentials)
            try engineStore.saveCredential(credentials)
            XCTAssertEqual(try hostAppStore.retrieveCredential(), stored, label)
        }
    }
}
