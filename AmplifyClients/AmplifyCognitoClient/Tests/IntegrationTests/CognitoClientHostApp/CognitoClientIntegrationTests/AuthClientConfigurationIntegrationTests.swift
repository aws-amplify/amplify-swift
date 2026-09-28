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

    /// The provisioned `amplify_outputs.json` loads through the public initializer.
    ///
    /// - Given: The sandbox's `amplify_outputs.json`, copied into the test bundle
    /// - When:
    ///    - `AuthClientConfiguration(from: "amplify_outputs", bundle:)` loads it
    /// - Then:
    ///    - Both pools match the ids `provision.sh` recorded independently in `state.json`
    ///    - The pool namespace is the user pool and identity pool together, as the plugin keys it
    ///
    func testLoadsProvisionedOutputsWithExpectedPoolNamespace() throws {
        try IntegrationTestEnvironment.requireProvisioned()
        let state = try IntegrationTestEnvironment.state()

        let configuration = try AuthClientConfiguration(
            from: IntegrationTestEnvironment.outputsResource,
            bundle: IntegrationTestEnvironment.bundle
        )

        let userPool = try XCTUnwrap(configuration.userPool)
        XCTAssertEqual(userPool.poolId, state.userPoolId)
        XCTAssertEqual(userPool.appClientId, state.appClientId)
        XCTAssertEqual(userPool.region, state.region)
        XCTAssertNil(userPool.appClientSecret)

        let identityPool = try XCTUnwrap(configuration.identityPool)
        XCTAssertEqual(identityPool.poolId, state.identityPoolId)
        XCTAssertEqual(identityPool.region, state.region)

        XCTAssertEqual(
            configuration.poolNamespace,
            .userPoolAndIdentityPool(userPoolId: state.userPoolId, identityPoolId: state.identityPoolId)
        )
        XCTAssertEqual(configuration.poolNamespace.keyComponent, "\(state.userPoolId).\(state.identityPoolId)")
    }

    /// The real configuration yields the keys the design specifies, beside the plugin's.
    ///
    /// - Given: The configuration loaded from the provisioned outputs
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
        let state = try IntegrationTestEnvironment.state()
        let configuration = try AuthClientConfiguration(
            from: IntegrationTestEnvironment.outputsResource,
            bundle: IntegrationTestEnvironment.bundle
        )
        let namespace = configuration.poolNamespace

        let v1 = SessionRecordKey.account(for: .default, in: namespace, kind: .session)
        XCTAssertEqual(v1, "amplify.1.\(state.userPoolId).\(state.identityPoolId).$default.session")
        XCTAssertEqual(
            SessionRecordKey.legacySessionAccount(in: namespace),
            "amplify.\(state.userPoolId).\(state.identityPoolId).session"
        )

        let parsed = try XCTUnwrap(SessionRecordKey.parse(v1))
        XCTAssertEqual(parsed.namespaceComponent, namespace.keyComponent)
        XCTAssertEqual(parsed.sessionId, .default)
        XCTAssertEqual(parsed.kind, .session)
    }
}
