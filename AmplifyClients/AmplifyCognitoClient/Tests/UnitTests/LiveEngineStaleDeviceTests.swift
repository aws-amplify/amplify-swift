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

    /// - Given: a device record for carol whose key Cognito has forgotten (an earlier carol deleted her account on
    ///   this device), a sign-up and confirmation of carol that leave `.completeAutoSignIn`, and Cognito refusing an
    ///   `InitiateAuth` that carries that key with `ResourceNotFoundException` ("Device does not exist.") and signing
    ///   carol in otherwise
    /// - When: carol's auto sign-in runs
    /// - Then:
    ///    - it is `.done`: two `InitiateAuth` calls with the confirmation's session, the first with the stale key and
    ///      the second with none
    ///    - carol's device record is gone
    func testAnAutoSignInAfterTheDeviceWasForgottenStartsAgainWithoutIt() async throws {
        try saveForgottenDevice(for: "carol")
        scriptSignUpWithAutoSignIn()
        harness.cognito.always("InitiateAuth") { (input: InitiateAuthInput) -> InitiateAuthOutput in
            if input.authParameters?["DEVICE_KEY"] != nil {
                throw AWSCognitoIdentityProvider.ResourceNotFoundException(message: "Device does not exist.")
            }
            return InitiateAuthOutput(authenticationResult: LiveEngineFixtures.tokens("carol"), challengeParameters: [:])
        }
        harness.scriptIdentityPool()
        let client = try makeClient()
        _ = try await client.signUp(username: "carol")
        _ = try await client.confirmSignUp(for: "carol", confirmationCode: "123456")

        let result = try await client.autoSignIn()

        XCTAssertEqual(result.nextStep, .done)
        let inputs = harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self)
        XCTAssertEqual(inputs.map { $0.authParameters?["DEVICE_KEY"] }, ["forgotten", nil])
        XCTAssertEqual(inputs.map(\.session), ["auto-session", "auto-session"])
        try assertNoDeviceRecord(for: "carol")
    }

    /// The retry reuses the sign-up's one-time session. If Cognito refuses it there, the auto sign-in throws.
    ///
    /// - Given: as above, but Cognito answers the `InitiateAuth` without a device key with `NotAuthorizedException`
    ///   ("Invalid session for the user.")
    /// - When: carol's auto sign-in runs
    /// - Then:
    ///    - it throws `.notAuthorized` after two `InitiateAuth` calls, the first with the stale key and the second
    ///      with none
    ///    - carol's device record is gone, so her next sign-in sends no stale key
    func testAnAutoSignInWhoseRetryIsRefusedThrows() async throws {
        try saveForgottenDevice(for: "carol")
        scriptSignUpWithAutoSignIn()
        harness.cognito.always("InitiateAuth") { (input: InitiateAuthInput) -> InitiateAuthOutput in
            if input.authParameters?["DEVICE_KEY"] != nil {
                throw AWSCognitoIdentityProvider.ResourceNotFoundException(message: "Device does not exist.")
            }
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Invalid session for the user.")
        }
        let client = try makeClient()
        _ = try await client.signUp(username: "carol")
        _ = try await client.confirmSignUp(for: "carol", confirmationCode: "123456")

        await assertThrowsAsync({ try await client.autoSignIn() }) { error in
            guard case .notAuthorized = authError(error) else {
                return XCTFail("\(error)")
            }
        }

        let deviceKeys = harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self).map { $0.authParameters?["DEVICE_KEY"] }
        XCTAssertEqual(deviceKeys, ["forgotten", nil])
        try assertNoDeviceRecord(for: "carol")
    }

    /// Saves a device record for `username` whose key Cognito has forgotten.
    private func saveForgottenDevice(for username: String) throws {
        let metadata = DeviceMetadata.metadata(.init(deviceKey: "forgotten", deviceGroupKey: "group"))
        try harness.keychain.deviceStore(for: harness.namespace).saveDeviceMetadata(metadata, for: username)
    }

    /// Scripts a sign-up that needs a code and a confirmation that leaves `.completeAutoSignIn("auto-session")`.
    private func scriptSignUpWithAutoSignIn() {
        harness.cognito.once("SignUp") { (_: SignUpInput) in
            SignUpOutput(session: "sign-up-session", userConfirmed: false, userSub: "sub")
        }
        harness.cognito.once("ConfirmSignUp") { (_: ConfirmSignUpInput) in ConfirmSignUpOutput(session: "auto-session") }
    }

    private func assertNoDeviceRecord(for username: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let record = try harness.keychain.deviceStore(for: harness.namespace).deviceMetadata(DeviceMetadata.self, for: username)
        guard case .absent = record else {
            return XCTFail("the stale device record was kept: \(record)", file: file, line: line)
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
