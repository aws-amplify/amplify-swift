//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

// The client is linked through its package product, built in Debug with testability on, so its
// internal symbols (`poolNamespace`, `SessionRecordKey`) are reachable through `@testable`.

final class AuthClientConfigurationIntegrationTests: XCTestCase {

    /// The default backend's outputs file loads through the public initializer.
    ///
    /// - Given: The plugin's default outputs file (`AWSCognitoAuthPluginIntegrationTests-amplify_outputs.json`),
    ///   copied into the test bundle, or the Gen2 translation of its Gen1 file where only that was copied
    /// - When:
    ///    - `AuthClientConfiguration(from:bundle:)` loads it by that resource name
    /// - Then:
    ///    - Both pools match the ids the file names, read independently as raw JSON
    ///    - The pool namespace is the user pool and identity pool together, as the plugin keys it
    ///
    func testLoadsProvisionedOutputsWithExpectedPoolNamespace() throws {
        try IntegrationTestEnvironment.requireProvisioned()
        let state = try RawOutputs()

        let configuration = try AuthClientConfiguration(
            from: IntegrationTestEnvironment.outputsResource,
            bundle: IntegrationTestEnvironment.outputsBundle(.standard)
        )

        let userPool = try XCTUnwrap(configuration.userPool)
        // Booleans, so a failure prints no identifier.
        XCTAssertTrue(userPool.poolId == state.userPoolId, "the user pool")
        XCTAssertTrue(userPool.appClientId == state.appClientId, "the app client")
        XCTAssertEqual(userPool.region, state.region)
        XCTAssertNil(userPool.appClientSecret)

        let identityPool = try XCTUnwrap(configuration.identityPool)
        XCTAssertTrue(identityPool.poolId == state.identityPoolId, "the identity pool")
        XCTAssertEqual(identityPool.region, state.region)

        XCTAssertTrue(
            configuration.poolNamespace
                == .userPoolAndIdentityPool(userPoolId: state.userPoolId, identityPoolId: state.identityPoolId),
            "the pool namespace"
        )
        XCTAssertTrue(configuration.poolNamespace.keyComponent == "\(state.userPoolId).\(state.identityPoolId)", "the key component")
    }

    /// The real configuration yields the keys the design specifies: `.default`'s session record is the plugin's
    /// own, and the rest stay in the client's v1 family beside it.
    ///
    /// - Given: The configuration loaded from the default backend's outputs
    /// - When:
    ///    - `.default`'s keys and a named session's v1 key are rendered for its namespace
    ///    - The v1 keys are parsed back
    /// - Then:
    ///    - `.default`'s session record is the plugin's `amplify.<userPoolId>.<identityPoolId>.session`
    ///    - its sidecar is `amplify.1.<userPoolId>.<identityPoolId>.$default.meta`, which does not parse as a
    ///      session record, and its interrupted sign-in `amplify.1.<userPoolId>.<identityPoolId>.$default.challenge`,
    ///      which parses as `.default`'s challenge
    ///    - a named session's record is `amplify.1.<userPoolId>.<identityPoolId>.<sessionId>.session`, and the
    ///      identity pool id's `:` survives the round trip through the parser
    ///
    func testProvisionedNamespaceRendersTheDefaultAndNamedSessionKeys() throws {
        try IntegrationTestEnvironment.requireProvisioned()
        let state = try RawOutputs()
        let configuration = try AuthClientConfiguration(
            from: IntegrationTestEnvironment.outputsResource,
            bundle: IntegrationTestEnvironment.outputsBundle(.standard)
        )
        let namespace = configuration.poolNamespace
        let component = "\(state.userPoolId).\(state.identityPoolId)"

        XCTAssertTrue(
            SessionRecordKey.pluginSessionAccount(in: namespace) == "amplify.\(component).session",
            "`.default`'s session record is not the plugin's key"
        )
        let sidecar = SessionRecordKey.metaAccount(in: namespace)
        XCTAssertTrue(sidecar == "amplify.1.\(component).$default.meta", "the sidecar's key")
        XCTAssertTrue(SessionRecordKey.parse(sidecar) == nil, "the sidecar parses as a session record")
        let challenge = SessionRecordKey.account(for: .default, in: namespace, kind: .challenge)
        XCTAssertTrue(challenge == "amplify.1.\(component).$default.challenge", "`.default`'s challenge key")
        let parsedChallenge = try XCTUnwrap(SessionRecordKey.parse(challenge))
        XCTAssertEqual(parsedChallenge.sessionId, .default)
        XCTAssertEqual(parsedChallenge.kind, .challenge)

        let work = try SessionID.named("work")
        let named = SessionRecordKey.account(for: work, in: namespace, kind: .session)
        XCTAssertTrue(named == "amplify.1.\(component).work.session", "the named session's key")
        let parsed = try XCTUnwrap(SessionRecordKey.parse(named))
        // A boolean, so a failure prints no identifier.
        XCTAssertTrue(parsed.namespaceComponent == namespace.keyComponent, "the identity pool id did not survive the round trip")
        XCTAssertEqual(parsed.sessionId, work)
        XCTAssertEqual(parsed.kind, .session)
    }
}

/// The ids the default outputs file names, read as raw JSON: an independent source to check the parsed
/// configuration against.
private struct RawOutputs {
    let region: String
    let userPoolId: String
    let appClientId: String
    let identityPoolId: String

    init() throws {
        let auth = try IntegrationTestEnvironment.outputsAuthSection(.standard)
        func value(_ key: String) throws -> String {
            try XCTUnwrap(auth[key] as? String, "\(IntegrationTestEnvironment.outputsResource).json has no \(key)")
        }
        self.region = try value("aws_region")
        self.userPoolId = try value("user_pool_id")
        self.appClientId = try value("user_pool_client_id")
        self.identityPoolId = try value("identity_pool_id")
    }
}
