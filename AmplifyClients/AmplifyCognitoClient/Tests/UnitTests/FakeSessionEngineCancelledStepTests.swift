//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// A held step that a cancel took, released after a newer sign-in began, leaves the newer sign-in's attempt alone, as
/// the live engine's `run` does.
final class FakeSessionEngineCancelledStepTests: XCTestCase {

    /// - Given: alice's sign-in at epoch 1 held by `holdSignIns(on:)`, and a cancel for everything before epoch 2
    /// - When:
    ///    - bob signs in at epoch 3, unheld, and stops on a TOTP challenge
    ///    - alice's sign-in is released
    /// - Then:
    ///    - alice's sign-in throws `CancellationError`, and bob's TOTP challenge is still the one pending
    func testACancelledStepReleasedLaterKeepsTheNewerAttempt() async throws {
        let engine = try makeEngine()
        let aliceGate = Gate()
        engine.holdSignIns(on: aliceGate)
        let alice = Task { try await engine.signIn(Self.request("alice"), current: nil, epoch: 1) }
        await aliceGate.waitForArrivals(1)
        await engine.cancelPendingSignIn(before: 2)

        let bobGate = Gate()
        await bobGate.open()
        engine.holdSignIns(on: bobGate)
        engine.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }
        let bob = try await engine.signIn(Self.request("bob"), current: nil, epoch: 3)
        await aliceGate.open()

        XCTAssertEqual(bob, .challenge(.confirmSignInWithTOTPCode))
        await assertThrowsAsync({ try await alice.value }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        let pending = await engine.pendingChallenge
        XCTAssertEqual(pending, .confirmSignInWithTOTPCode)
    }

    // MARK: Helpers

    private func makeEngine() throws -> FakeSessionEngine {
        let configuration = try AuthClientConfiguration(
            userPool: .init(poolId: StorageFixtures.userPoolId, appClientId: "app-client-1", region: "us-east-1"),
            identityPool: .init(poolId: StorageFixtures.identityPoolId, region: "us-east-1")
        )
        let clients = try CognitoServiceClients(configuration: configuration, configureUserPoolClient: nil)
        return FakeSessionEngine(context: SessionEngineContext(
            sessionId: .default,
            configuration: configuration,
            namespace: StorageFixtures.namespace,
            clients: clients
        ))
    }

    private static func request(_ username: String) -> EngineSignInRequest {
        EngineSignInRequest(username: username, password: "password", authFlowType: nil, clientMetadata: [:])
    }
}
