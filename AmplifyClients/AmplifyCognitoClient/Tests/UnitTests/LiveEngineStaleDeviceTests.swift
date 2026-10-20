//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// After `forgetDevice()`, which keeps this device's record as the plugin does, a sign-in sends a device key Cognito
/// no longer knows. Every flow that sends it in its first request starts again without it, as SRP does, so the user
/// can sign in.
final class LiveEngineStaleDeviceTests: XCTestCase {

    private var harness: LiveEngineHarness!

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
    }

    override func tearDown() {
        harness = nil
        super.tearDown()
    }

    /// - Given: a device record for alice whose key Cognito has forgotten, and Cognito refusing an `InitiateAuth` that
    ///   carries that key with `ResourceNotFoundException` ("Device does not exist.") and signing alice in otherwise
    /// - When: alice signs in through a client with `.userPassword` (`USER_PASSWORD_AUTH`)
    /// - Then:
    ///    - the sign-in is `.done`: two `InitiateAuth` calls, the first with the stale key and the second with none
    ///    - alice's device record is gone, so the next sign-in sends no stale key
    func testAPasswordSignInAfterTheDeviceWasForgottenStartsAgainWithoutIt() async throws {
        let metadata = DeviceMetadata.metadata(.init(deviceKey: "forgotten", deviceGroupKey: "group"))
        try harness.keychain.deviceStore(for: harness.namespace).saveDeviceMetadata(metadata, for: "alice")
        harness.cognito.always("InitiateAuth") { (input: InitiateAuthInput) -> InitiateAuthOutput in
            if input.authParameters?["DEVICE_KEY"] != nil {
                throw AWSCognitoIdentityProvider.ResourceNotFoundException(message: "Device does not exist.")
            }
            return InitiateAuthOutput(authenticationResult: LiveEngineFixtures.tokens(), challengeParameters: [:])
        }
        harness.scriptIdentityPool()
        let client = try makeClient()

        let result = try await client.signIn(username: "alice", password: "pw", options: .init(authFlowType: .userPassword))

        XCTAssertEqual(result.nextStep, .done)
        let deviceKeys = harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self).map { $0.authParameters?["DEVICE_KEY"] }
        XCTAssertEqual(deviceKeys, ["forgotten", nil])
        let record = try harness.keychain.deviceStore(for: harness.namespace).deviceMetadata(DeviceMetadata.self, for: "alice")
        guard case .absent = record else {
            return XCTFail("the stale device record was kept: \(record)")
        }
    }

    /// A client of `work` over this test's live engine.
    private func makeClient() throws -> AmplifyCognitoClient {
        let base = ClientHarness().dependencies
        let harness = harness!
        let dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in try harness.engine() },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: { Date() }
        )
        return try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: ClientFixtures.id("work")),
            dependencies: dependencies
        )
    }
}
