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

/// The live engine's device operations over scripted Cognito,
/// ported from the plugin's `AWSAuthFetchDevicesTask`, `AWSAuthRememberDeviceTask` and
/// `AWSAuthForgetDeviceTask`.
final class LiveEngineDevicesTests: XCTestCase {

    private var harness: LiveEngineHarness!

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
    }

    override func tearDown() {
        harness = nil
        super.tearDown()
    }

    // MARK: Helpers

    /// Signs `typed` in through SRP, with tokens for `tokenUsername` (the JWT's username, which differs
    /// from the typed one for an email alias), then forgets the calls it took.
    private func signedIn(
        _ typed: String = "alice",
        tokenUsername: String? = nil,
        on engine: LiveSessionEngine
    ) async throws -> Data {
        harness.scriptSRP(typed, then: tokenUsername.map { LiveEngineFixtures.signedIn($0) })
        harness.scriptIdentityPool()
        guard case .done(let payload) = try await engine.signIn(.srp(typed), current: nil) else {
            throw FixtureError(description: "the scripted sign-in did not finish")
        }
        harness.cognito.clearCalls()
        return payload
    }

    /// Writes the device record sign-in's `ConfirmDevice` would have written for `username`.
    private func storeDevice(_ deviceKey: String, for username: String) throws {
        let metadata = DeviceMetadata.metadata(.init(deviceKey: deviceKey, deviceGroupKey: "group-\(deviceKey)"))
        try harness.keychain.deviceStore(for: harness.namespace).saveDeviceMetadata(metadata, for: username)
    }

    private func scriptDeviceCalls() {
        harness.cognito.always("UpdateDeviceStatus") { (_: UpdateDeviceStatusInput) in UpdateDeviceStatusOutput() }
        harness.cognito.always("ForgetDevice") { (_: ForgetDeviceInput) in ForgetDeviceOutput() }
    }

    private func accessToken(in payload: Data) throws -> String {
        try XCTUnwrap(AmplifyCredentials.decoded(payload).signedInData?.cognitoUserPoolTokens.accessToken)
    }

    // MARK: fetchDevices

    /// Test that the listed devices are mapped as the plugin maps them.
    ///
    /// - Given: alice signed in; Cognito lists one device with a name, another attribute, an unnamed
    ///   attribute and three dates, and one device with nothing
    /// - When:
    ///    - `fetchDevices`
    /// - Then:
    ///    - one `ListDevices` call, with the payload's access token
    ///    - the first device has the key as its id, `device_name` as its name, the named attributes and the
    ///      dates; the second has an empty id and name, no attributes, and no dates
    ///
    func testFetchDevicesMapsTheListAsThePluginDoes() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let authenticated = Date(timeIntervalSince1970: 1_700_000_100)
        let modified = Date(timeIntervalSince1970: 1_700_000_200)
        harness.cognito.always("ListDevices") { (_: ListDevicesInput) in
            ListDevicesOutput(devices: [
                .init(
                    deviceAttributes: [
                        .init(name: "device_name", value: "iPhone"),
                        .init(name: "last_ip_used", value: "192.0.2.1"),
                        .init(name: nil, value: "dropped")
                    ],
                    deviceCreateDate: created,
                    deviceKey: "us-east-1_device-1",
                    deviceLastAuthenticatedDate: authenticated,
                    deviceLastModifiedDate: modified
                ),
                .init()
            ])
        }

        let devices = try await engine.fetchDevices(payload)

        XCTAssertEqual(harness.cognito.operations, ["ListDevices"])
        let token = try accessToken(in: payload)
        XCTAssertEqual(harness.cognito.inputs("ListDevices", as: ListDevicesInput.self).map(\.accessToken), [token])
        XCTAssertEqual(devices, [
            AuthClientDevice(
                id: "us-east-1_device-1",
                name: "iPhone",
                attributes: ["device_name": "iPhone", "last_ip_used": "192.0.2.1"],
                createdDate: created,
                lastAuthenticatedDate: authenticated,
                lastModifiedDate: modified
            ),
            AuthClientDevice(id: "", name: "", attributes: [:])
        ])
    }

    /// Test that a response without a device list fails as the plugin's does.
    ///
    /// - Given: alice signed in; Cognito answers `ListDevices` with no `Devices`
    /// - When:
    ///    - `fetchDevices`
    /// - Then:
    ///    - `unknown` "Unable to get devices list from response"
    ///
    func testFetchDevicesWithoutAListIsUnknown() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.cognito.always("ListDevices") { (_: ListDevicesInput) in ListDevicesOutput(devices: nil) }

        await assertThrowsAsync({ try await engine.fetchDevices(payload) }) { error in
            guard case .unknown(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "Unable to get devices list from response")
        }
    }

    /// Test that Cognito's failures are mapped as the plugin maps them.
    ///
    /// - Given: alice signed in; each device call answers `NotAuthorizedException`
    /// - When:
    ///    - `fetchDevices`, `rememberDevice` and `forgetDevice(deviceId:)`
    /// - Then:
    ///    - each throws `.notAuthorized` with Cognito's message
    ///
    func testCognitoFailuresAreMapped() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        try storeDevice("device-alice", for: "alice")
        let failure = AWSCognitoIdentityProvider.NotAuthorizedException(message: "Access Token has been revoked")
        harness.cognito.always("ListDevices") { (_: ListDevicesInput) -> ListDevicesOutput in throw failure }
        harness.cognito.always("UpdateDeviceStatus") { (_: UpdateDeviceStatusInput) -> UpdateDeviceStatusOutput in throw failure }
        harness.cognito.always("ForgetDevice") { (_: ForgetDeviceInput) -> ForgetDeviceOutput in throw failure }

        let calls: [() async throws -> Any] = [
            { try await engine.fetchDevices(payload) },
            { try await engine.rememberDevice(payload) },
            { try await engine.forgetDevice(payload, deviceId: "device-other") }
        ]
        for call in calls {
            await assertThrowsAsync({ try await call() }) { error in
                guard case .notAuthorized(let description, _, _) = authError(error) else {
                    return XCTFail("\(error)")
                }
                XCTAssertEqual(description, "Access Token has been revoked")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["ListDevices", "UpdateDeviceStatus", "ForgetDevice"])
    }

    // MARK: rememberDevice

    /// Test that remembering marks this device, from the user's device record, remembered.
    ///
    /// - Given: alice signed in, with a device record
    /// - When:
    ///    - `rememberDevice`
    /// - Then:
    ///    - one `UpdateDeviceStatus`: the payload's access token, the record's key, `remembered`
    ///    - the payload is not changed (the engine returns nothing to commit)
    ///
    func testRememberDeviceUsesTheDeviceRecordsKey() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        try storeDevice("device-alice", for: "alice")
        scriptDeviceCalls()

        try await engine.rememberDevice(payload)

        let inputs = harness.cognito.inputs("UpdateDeviceStatus", as: UpdateDeviceStatusInput.self)
        XCTAssertEqual(harness.cognito.operations, ["UpdateDeviceStatus"])
        XCTAssertEqual(inputs.first?.accessToken, try accessToken(in: payload))
        XCTAssertEqual(inputs.first?.deviceKey, "device-alice")
        XCTAssertEqual(inputs.first?.deviceRememberedStatus, .remembered)
    }

    /// Test that without a device record nothing is sent, and the plugin's error is thrown.
    ///
    /// - Given: alice signed in, with no device record (the pool does not track devices)
    /// - When:
    ///    - `rememberDevice`, then `forgetDevice(deviceId: nil)`
    /// - Then:
    ///    - each throws `unknown` "Unable to get device metadata"; no Cognito call is made
    ///
    func testWithoutADeviceRecordThisDeviceIsUnknown() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        scriptDeviceCalls()

        let calls: [() async throws -> Void] = [
            { try await engine.rememberDevice(payload) },
            { try await engine.forgetDevice(payload, deviceId: nil) }
        ]
        for call in calls {
            await assertThrowsAsync({ try await call() }) { error in
                guard case .unknown(let description, _, _) = authError(error) else {
                    return XCTFail("\(error)")
                }
                XCTAssertEqual(description, "Unable to get device metadata")
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// Test that a record holding no device (`noData`) or bytes that do not decode count as missing.
    ///
    /// - Given: alice signed in; her record is first `noData`, then undecodable
    /// - When:
    ///    - `rememberDevice` each time
    /// - Then:
    ///    - each throws `unknown` "Unable to get device metadata"; no Cognito call is made
    ///
    func testAnUnusableDeviceRecordIsMissing() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        scriptDeviceCalls()
        let store = harness.keychain.deviceStore(for: harness.namespace)

        try store.saveDeviceMetadata(DeviceMetadata.noData, for: "alice")
        await assertThrowsAsync({ try await engine.rememberDevice(payload) }) { error in
            XCTAssertEqual(authError(error)?.errorDescription, "Unable to get device metadata")
        }
        try store.saveDeviceMetadata("not device metadata", for: "alice")
        await assertThrowsAsync({ try await engine.rememberDevice(payload) }) { error in
            XCTAssertEqual(authError(error)?.errorDescription, "Unable to get device metadata")
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// Test that a keychain failure reading the device record is `storageUnavailable`, never "absent": the
    /// client's store rule, and a deliberate divergence from the plugin, whose helper reports "Unable to get
    /// device metadata" for any read failure.
    ///
    /// - Given: alice signed in, with a device record whose keychain read fails
    ///   (`errSecInteractionNotAllowed`, the device is locked)
    /// - When:
    ///    - `rememberDevice`, then `forgetDevice(deviceId: nil)`
    /// - Then:
    ///    - each throws `storageUnavailable`; no Cognito call is made
    ///    - once the keychain reads again, `rememberDevice` sends the record's key
    ///
    func testAKeychainFailureReadingTheRecordIsStorageUnavailable() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        try storeDevice("device-alice", for: "alice")
        scriptDeviceCalls()
        let store = harness.keychain.deviceStore(for: harness.namespace)
        harness.keychain.failingReads(of: store.deviceMetadataAccount(for: "alice"), with: errSecInteractionNotAllowed)

        let calls: [() async throws -> Void] = [
            { try await engine.rememberDevice(payload) },
            { try await engine.forgetDevice(payload, deviceId: nil) }
        ]
        for call in calls {
            await assertThrowsAsync({ try await call() }) { error in
                guard case .storageUnavailable = authError(error) else {
                    return XCTFail("\(error)")
                }
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])

        harness.keychain.clearFailures()
        try await engine.rememberDevice(payload)
        XCTAssertEqual(harness.cognito.inputs("UpdateDeviceStatus", as: UpdateDeviceStatusInput.self).map(\.deviceKey), ["device-alice"])
    }

    // MARK: forgetDevice

    /// Test that forgetting this device uses the record's key and keeps the record, as the plugin does.
    ///
    /// - Given: alice signed in, with a device record
    /// - When:
    ///    - `forgetDevice(deviceId: nil)`
    /// - Then:
    ///    - one `ForgetDevice`: the payload's access token and the record's key
    ///    - the record is still there
    ///
    func testForgetThisDeviceUsesTheRecordAndKeepsIt() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        try storeDevice("device-alice", for: "alice")
        scriptDeviceCalls()

        try await engine.forgetDevice(payload, deviceId: nil)

        let inputs = harness.cognito.inputs("ForgetDevice", as: ForgetDeviceInput.self)
        XCTAssertEqual(harness.cognito.operations, ["ForgetDevice"])
        XCTAssertEqual(inputs.first?.accessToken, try accessToken(in: payload))
        XCTAssertEqual(inputs.first?.deviceKey, "device-alice")
        let kept = try harness.keychain.deviceStore(for: harness.namespace).deviceMetadata(DeviceMetadata.self, for: "alice")
        guard case .value(.metadata(let data)) = kept else {
            return XCTFail("the device record was removed")
        }
        XCTAssertEqual(data.deviceKey, "device-alice")
    }

    /// Test that forgetting a listed device sends its id and reads no record.
    ///
    /// - Given: alice signed in, with no device record
    /// - When:
    ///    - `forgetDevice(deviceId: "device-other")`
    /// - Then:
    ///    - one `ForgetDevice` with that key
    ///
    func testForgetAListedDeviceSendsItsId() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        scriptDeviceCalls()

        try await engine.forgetDevice(payload, deviceId: "device-other")

        XCTAssertEqual(harness.cognito.operations, ["ForgetDevice"])
        XCTAssertEqual(harness.cognito.inputs("ForgetDevice", as: ForgetDeviceInput.self).first?.deviceKey, "device-other")
    }

    // MARK: The device record's username (#4207)

    /// Test that an email-alias user's record is found under the name typed at sign-in, before and after a
    /// refresh, not under the JWT's username.
    ///
    /// - Given: a user signed in as `Alice@Example.com`, whose tokens name `generated-sub`; the device
    ///   record is under the typed name only
    /// - When:
    ///    - `rememberDevice`; then the payload is refreshed; then `forgetDevice(deviceId: nil)`
    /// - Then:
    ///    - both calls send the record's key: `inputUsername` survives the refresh
    ///
    func testAnEmailAliasFindsTheRecordUnderTheTypedName() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn("Alice@Example.com", tokenUsername: "generated-sub", on: engine)
        XCTAssertEqual(try AmplifyCredentials.decoded(payload).signedInData?.username, "generated-sub")
        try storeDevice("device-alias", for: "Alice@Example.com")
        scriptDeviceCalls()
        harness.scriptRefresh("generated-sub")

        try await engine.rememberDevice(payload)
        let refreshed = try await engine.refresh(payload, force: true)
        try await engine.forgetDevice(refreshed, deviceId: nil)

        XCTAssertEqual(harness.cognito.inputs("UpdateDeviceStatus", as: UpdateDeviceStatusInput.self).map(\.deviceKey), ["device-alias"])
        XCTAssertEqual(harness.cognito.inputs("ForgetDevice", as: ForgetDeviceInput.self).map(\.deviceKey), ["device-alias"])
        let refreshedToken = try accessToken(in: refreshed)
        XCTAssertEqual(harness.cognito.inputs("ForgetDevice", as: ForgetDeviceInput.self).map(\.accessToken), [refreshedToken])
    }

    // MARK: Sessions

    /// Test that the device record is per user, not per session: two sessions of one user share it, and a
    /// session of another user never reads it.
    ///
    /// - Given: three engines (three sessions) on one namespace: `work` and `home` hold alice, `other`
    ///   holds bob; alice and bob each have a device record
    /// - When:
    ///    - each session calls `rememberDevice`
    /// - Then:
    ///    - `work` and `home` send alice's key, `other` sends bob's
    ///    - with bob's record removed, `other` fails with "Unable to get device metadata" and sends nothing,
    ///      although alice's record is still there
    ///
    func testDeviceRecordsArePerUserAcrossSessions() async throws {
        let work = try harness.engine()
        let home = try harness.engine()
        let other = try harness.engine()
        let workPayload = try await signedIn("alice", on: work)
        let homePayload = try await signedIn("alice", on: home)
        let otherPayload = try await signedIn("bob", on: other)
        try storeDevice("device-alice", for: "alice")
        try storeDevice("device-bob", for: "bob")
        scriptDeviceCalls()

        try await work.rememberDevice(workPayload)
        try await home.rememberDevice(homePayload)
        try await other.rememberDevice(otherPayload)

        XCTAssertEqual(
            harness.cognito.inputs("UpdateDeviceStatus", as: UpdateDeviceStatusInput.self).map(\.deviceKey),
            ["device-alice", "device-alice", "device-bob"]
        )

        harness.cognito.clearCalls()
        try harness.keychain.deviceStore(for: harness.namespace).removeDeviceMetadata(for: "bob")
        await assertThrowsAsync({ try await other.rememberDevice(otherPayload) }) { error in
            XCTAssertEqual(authError(error)?.errorDescription, "Unable to get device metadata")
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// Test that the device record is per namespace: a session in another access group, or on another user
    /// pool, never reads the record of the same username in this one.
    ///
    /// - Given: alice signed in on three sessions: one in the default namespace, which holds her device
    ///   record, one in the access group `group.other`, and one whose namespace names another user pool
    /// - When:
    ///    - each session calls `rememberDevice`; then a record of its own is written in `group.other` and the
    ///      two sessions there and in the default namespace call it again
    /// - Then:
    ///    - the default session sends its key; the other two fail with "Unable to get device metadata" and
    ///      send nothing
    ///    - afterwards each of the two sends its own namespace's key
    ///
    func testDeviceRecordsArePerNamespace() async throws {
        let otherPool = ClientFixtures.make(
            userPool: .init(poolId: "us-east-1_OtherPool", appClientId: "app-client-1", region: "us-east-1"),
            identityPool: ClientFixtures.identityPool
        )
        let otherGroup = SessionStorageNamespace(pools: harness.configuration.poolNamespace, accessGroup: "group.other")
        let otherPoolNamespace = SessionStorageNamespace(pools: otherPool.poolNamespace, accessGroup: nil)
        XCTAssertNotEqual(otherPool.poolNamespace, harness.configuration.poolNamespace)

        let home = try harness.engine()
        let grouped = try engine(in: otherGroup)
        let pooled = try engine(in: otherPoolNamespace)
        let homePayload = try await signedIn("alice", on: home)
        let groupedPayload = try await signedIn("alice", on: grouped)
        let pooledPayload = try await signedIn("alice", on: pooled)
        try storeDevice("device-home", for: "alice")
        scriptDeviceCalls()

        try await home.rememberDevice(homePayload)
        for (engine, payload) in [(grouped, groupedPayload), (pooled, pooledPayload)] {
            await assertThrowsAsync({ try await engine.rememberDevice(payload) }) { error in
                XCTAssertEqual(authError(error)?.errorDescription, "Unable to get device metadata")
            }
        }
        XCTAssertEqual(harness.cognito.inputs("UpdateDeviceStatus", as: UpdateDeviceStatusInput.self).map(\.deviceKey), ["device-home"])

        harness.cognito.clearCalls()
        let metadata = DeviceMetadata.metadata(.init(deviceKey: "device-grouped", deviceGroupKey: "group-grouped"))
        try harness.keychain.deviceStore(for: otherGroup).saveDeviceMetadata(metadata, for: "alice")
        try await grouped.rememberDevice(groupedPayload)
        try await home.rememberDevice(homePayload)
        XCTAssertEqual(
            harness.cognito.inputs("UpdateDeviceStatus", as: UpdateDeviceStatusInput.self).map(\.deviceKey),
            ["device-grouped", "device-home"]
        )
    }

    /// An engine like `harness.engine()`, whose device records are in `namespace`.
    private func engine(in namespace: SessionStorageNamespace) throws -> LiveSessionEngine {
        let base = try harness.resources()
        return LiveSessionEngine(resources: EngineResources(
            authConfiguration: base.authConfiguration,
            clients: base.clients,
            devices: DeviceRecordIO(store: harness.keychain.deviceStore(for: namespace)),
            analytics: base.analytics,
            services: base.services,
            makeAdvancedSecurity: base.makeAdvancedSecurity
        ))
    }

    /// Test that a payload without a user-pool user is refused before any call.
    ///
    /// - Given: a guest payload
    /// - When:
    ///    - each device operation
    /// - Then:
    ///    - each throws `SessionEngineError.notSignedIn`; no Cognito call is made
    ///
    func testAGuestPayloadIsNotSignedIn() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool()
        let guest = try await engine.fetchGuestCredentials(current: nil)
        harness.cognito.clearCalls()

        let calls: [() async throws -> Any] = [
            { try await engine.fetchDevices(guest) },
            { try await engine.rememberDevice(guest) },
            { try await engine.forgetDevice(guest, deviceId: "device-other") }
        ]
        for call in calls {
            await assertThrowsAsync({ try await call() }) { error in
                guard case SessionEngineError.notSignedIn = error else {
                    return XCTFail("\(error)")
                }
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }
}
