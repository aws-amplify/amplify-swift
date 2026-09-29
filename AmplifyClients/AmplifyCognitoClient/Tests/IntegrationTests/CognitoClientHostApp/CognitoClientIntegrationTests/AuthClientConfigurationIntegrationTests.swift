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
    ///   copied into the test bundle
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
            bundle: IntegrationTestEnvironment.bundle
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

    /// The real configuration yields the keys the design specifies, beside the plugin's.
    ///
    /// - Given: The configuration loaded from the default backend's outputs
    /// - When:
    ///    - The v1 session key and the plugin's legacy key are rendered for its namespace
    ///    - The v1 key is parsed back
    /// - Then:
    ///    - `amplify.1.<userPoolId>.<identityPoolId>.$default.session` and
    ///      `amplify.<userPoolId>.<identityPoolId>.session` — siblings, not replacements
    ///    - The identity pool id's `:` survives the round trip through the parser
    ///
    func testProvisionedNamespaceRendersV1AndLegacyKeys() throws {
        try IntegrationTestEnvironment.requireProvisioned()
        let state = try RawOutputs()
        let configuration = try AuthClientConfiguration(
            from: IntegrationTestEnvironment.outputsResource,
            bundle: IntegrationTestEnvironment.bundle
        )
        let namespace = configuration.poolNamespace

        let v1 = SessionRecordKey.account(for: .default, in: namespace, kind: .session)
        XCTAssertTrue(v1 == "amplify.1.\(state.userPoolId).\(state.identityPoolId).$default.session", "the v1 key")
        XCTAssertTrue(
            SessionRecordKey.legacySessionAccount(in: namespace) == "amplify.\(state.userPoolId).\(state.identityPoolId).session",
            "the plugin's key"
        )

        let parsed = try XCTUnwrap(SessionRecordKey.parse(v1))
        XCTAssertEqual(parsed.namespaceComponent, namespace.keyComponent)
        XCTAssertEqual(parsed.sessionId, .default)
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
        let auth = try IntegrationTestEnvironment.outputsAuthSection(IntegrationTestEnvironment.outputsResource)
        func value(_ key: String) throws -> String {
            try XCTUnwrap(auth[key] as? String, "\(IntegrationTestEnvironment.outputsResource).json has no \(key)")
        }
        self.region = try value("aws_region")
        self.userPoolId = try value("user_pool_id")
        self.appClientId = try value("user_pool_client_id")
        self.identityPoolId = try value("identity_pool_id")
    }
}
