//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The credential-store boundary. Session credentials live in the operation's
/// in-memory slot and never reach the keychain; device and ASF records go to the per-user keys through
/// `DeviceRecordStore`, with its reads mapped onto the engine's errors as the plugin's store reports them.
final class ClientCredentialStoreTests: XCTestCase {

    private var keychain: TestKeychain!

    override func setUp() {
        super.setUp()
        keychain = TestKeychain()
    }

    override func tearDown() {
        keychain = nil
        super.tearDown()
    }

    private func store(seed: Data? = nil) throws -> ClientCredentialStore {
        try ClientCredentialStore(
            slot: CredentialSlot(payload: seed),
            devices: DeviceRecordIO(store: keychain.deviceStore(for: StorageFixtures.namespace))
        )
    }

    private func deviceAccount(_ username: String) -> String {
        DeviceRecordStore.deviceMetadataAccount(for: username, in: StorageFixtures.pools)
    }

    private func asfAccount(_ username: String) -> String {
        DeviceRecordStore.asfDeviceAccount(for: username, in: StorageFixtures.pools)
    }

    private let metadata = DeviceMetadata.metadata(.init(deviceKey: "key", deviceGroupKey: "group", deviceSecret: "secret"))

    // MARK: Session credentials: in memory

    /// With no payload, the engine finds no credentials, and that is "not found", never a failure.
    ///
    /// - Given: a slot seeded with no payload, and one seeded with the `noCredentials` fixture
    /// - When:
    ///    - the engine retrieves its credentials
    /// - Then:
    ///    - both throw `itemNotFound`, the outcome is "unchanged", and the keychain saw nothing
    ///
    func testAbsentCredentialsAreItemNotFound() throws {
        for seed in [nil, try EnginePayloadFixtures.data("noCredentials")] {
            let store = try store(seed: seed)
            XCTAssertThrowsError(try store.retrieveCredential()) { error in
                XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
            }
            XCTAssertEqual(try store.slot.outcome(), .unchanged)
        }
        XCTAssertEqual(keychain.readAccounts, [])
        XCTAssertFalse(keychain.hasMutations)
    }

    /// A seeded payload is what the engine reads, decoded with the plugin store's coder.
    ///
    /// - Given: a slot seeded with each frozen payload that holds credentials
    /// - When:
    ///    - the engine retrieves its credentials
    /// - Then:
    ///    - it gets the fixture's value; the outcome is "unchanged"; the keychain saw nothing
    ///
    func testSeededPayloadIsRetrieved() throws {
        for caseName in EnginePayloadFixtures.caseNames where caseName != "noCredentials" {
            let store = try store(seed: EnginePayloadFixtures.data(caseName))
            XCTAssertEqual(try store.retrieveCredential(), try EnginePayloadFixtures.credentials(caseName), caseName)
            XCTAssertEqual(try store.slot.outcome(), .unchanged, caseName)
        }
        XCTAssertEqual(keychain.readAccounts, [])
        XCTAssertFalse(keychain.hasMutations)
    }

    /// A write stays in the slot and comes back as the payload to commit.
    ///
    /// - Given: a slot seeded with the guest fixture
    /// - When:
    ///    - the engine saves the signed-in fixture's credentials, then reads them back
    /// - Then:
    ///    - it reads what it saved; the outcome is `.written` with a payload that decodes, with the plugin's
    ///      coder, to exactly those credentials; the keychain saw nothing
    ///
    func testWriteStaysInMemoryAndIsTheOutcome() throws {
        let store = try store(seed: EnginePayloadFixtures.data("identityPoolOnly"))
        let signedIn = try EnginePayloadFixtures.credentials("userPoolAndIdentityPool")

        try store.saveCredential(signedIn)

        XCTAssertEqual(try store.retrieveCredential(), signedIn)
        guard case .written(let payload) = try store.slot.outcome() else {
            return XCTFail("expected a written outcome")
        }
        XCTAssertEqual(try JSONDecoder().decode(AmplifyCredentials.self, from: payload), signedIn)
        XCTAssertEqual(keychain.readAccounts, [])
        XCTAssertFalse(keychain.hasMutations)
    }

    /// A delete clears the slot, and the engine then finds nothing.
    ///
    /// - Given: a slot seeded with the signed-in fixture
    /// - When:
    ///    - the engine deletes its credentials
    /// - Then:
    ///    - a retrieve throws `itemNotFound`; the outcome is `.cleared`; the keychain saw nothing
    ///
    func testDeleteClearsTheSlot() throws {
        let store = try store(seed: EnginePayloadFixtures.data("userPoolOnly"))

        try store.deleteCredential()

        XCTAssertThrowsError(try store.retrieveCredential()) { error in
            XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
        }
        XCTAssertEqual(try store.slot.outcome(), .cleared)
        XCTAssertEqual(keychain.readAccounts, [])
        XCTAssertFalse(keychain.hasMutations)
    }

    /// A payload that is not credentials is refused when the operation is built.
    ///
    /// - Given: bytes that are not an `AmplifyCredentials` payload
    /// - When:
    ///    - a slot is seeded with them
    /// - Then:
    ///    - it throws a decoding error
    ///
    func testUndecodablePayloadIsRefused() {
        XCTAssertThrowsError(try CredentialSlot(payload: Data("not a payload".utf8))) { error in
            XCTAssertTrue(error is DecodingError, "\(error)")
        }
    }

    // MARK: Device and ASF records: the per-user keychain keys

    /// Device metadata goes to the plugin's per-user key, with the plugin's value format.
    ///
    /// - Given: an empty keychain
    /// - When:
    ///    - the engine saves device metadata for `Alice`, reads it back for `alice`, then removes it
    /// - Then:
    ///    - every call names the lower-cased per-user account; the stored value is the plugin's encoding;
    ///      the read returns what was saved; after the removal a read is `itemNotFound`
    ///
    func testDeviceMetadataUsesThePerUserKey() async throws {
        let store = try store()
        let account = deviceAccount("alice")

        try await store.saveDevice(metadata, for: "Alice")
        XCTAssertEqual(keychain.writtenAccounts, [account])
        let stored = try XCTUnwrap(keychain.value(account))
        XCTAssertEqual(try JSONDecoder().decode(DeviceMetadata.self, from: stored), metadata)
        let read = try await store.retrieveDevice(for: "alice")
        XCTAssertEqual(read, metadata)

        try await store.removeDevice(for: "Alice")
        XCTAssertEqual(keychain.removedAccounts, [account])
        await assertThrows(.itemNotFound) { _ = try await store.retrieveDevice(for: "alice") }
    }

    /// The ASF device ID goes to the plugin's per-user key, which keeps the username's case.
    ///
    /// - Given: an empty keychain
    /// - When:
    ///    - the engine saves an ASF device ID for `Alice`, and reads it for `Alice` and for `alice`
    /// - Then:
    ///    - the account keeps `Alice`'s case; the read for `Alice` returns the ID; the read for `alice` is
    ///      `itemNotFound`, as for the plugin
    ///
    func testASFDeviceIdKeepsTheUsernamesCase() async throws {
        let store = try store()

        try await store.saveASFDevice("asf-id", for: "Alice")

        XCTAssertEqual(keychain.writtenAccounts, [asfAccount("Alice")])
        let read = try await store.retrieveASFDevice(for: "Alice")
        XCTAssertEqual(read, "asf-id")
        await assertThrows(.itemNotFound) { _ = try await store.retrieveASFDevice(for: "alice") }

        try await store.removeASFDevice(for: "Alice")
        XCTAssertEqual(keychain.removedAccounts, [asfAccount("Alice")])
    }

    /// A stored value that is not a record is the plugin store's coding error, not "not found".
    ///
    /// - Given: bytes that are neither device metadata nor a string at both per-user keys
    /// - When:
    ///    - the engine reads them
    /// - Then:
    ///    - both reads throw `codingError`
    ///
    func testUndecodableRecordIsACodingError() async throws {
        keychain.put(Data("{".utf8), deviceAccount("alice"))
        keychain.put(Data("{".utf8), asfAccount("alice"))
        let store = try store()

        await assertThrows(.codingError("", nil)) { _ = try await store.retrieveDevice(for: "alice") }
        await assertThrows(.codingError("", nil)) { _ = try await store.retrieveASFDevice(for: "alice") }
    }

    /// A keychain failure is the engine's keychain failure, never "not found".
    ///
    /// - Given: a keychain whose reads, writes and removals fail with `errSecInteractionNotAllowed`
    /// - When:
    ///    - the engine reads, saves and removes both records
    /// - Then:
    ///    - every call throws `securityError` with that status, so the engine never reads a locked device as
    ///      "no device record"
    ///
    func testKeychainFailureIsASecurityErrorNotItemNotFound() async throws {
        let store = try store()
        for operation in [TestKeychain.Operation.read, .write, .remove] {
            keychain.failing(operation, with: errSecInteractionNotAllowed)
        }

        let calls: [(String, () async throws -> Void)] = [
            ("retrieveDevice", { _ = try await store.retrieveDevice(for: "alice") }),
            ("saveDevice", { try await store.saveDevice(self.metadata, for: "alice") }),
            ("removeDevice", { try await store.removeDevice(for: "alice") }),
            ("retrieveASFDevice", { _ = try await store.retrieveASFDevice(for: "alice") }),
            ("saveASFDevice", { try await store.saveASFDevice("asf-id", for: "alice") }),
            ("removeASFDevice", { try await store.removeASFDevice(for: "alice") })
        ]
        for (name, call) in calls {
            do {
                try await call()
                XCTFail("\(name) did not throw")
            } catch let error as EngineCredentialStoreError {
                guard case .securityError(let status) = error else {
                    return XCTFail("\(name) threw \(error)")
                }
                XCTAssertEqual(status, errSecInteractionNotAllowed, name)
            }
        }
    }

    /// A client error with no keychain status underneath is the engine's `unknown`, carrying it.
    ///
    /// - Given: client errors a device-record call can throw without a keychain status
    /// - When:
    ///    - they are mapped onto the engine's errors
    /// - Then:
    ///    - each is `unknown` with the client's error underneath, never `itemNotFound`
    ///
    func testOtherStorageFailuresAreUnknown() {
        let errors: [AuthClientError] = [
            .unknown("encode", "bug"),
            .storageUnavailable(.interrupted, "d", "s", KeychainAccessError.itemNotFound)
        ]
        for error in errors {
            let mapped = ClientCredentialStore.engineError(for: error)
            guard case .unknown(_, let underlying) = mapped else {
                return XCTFail("\(error) mapped to \(mapped)")
            }
            XCTAssertNotNil(underlying as? AuthClientError)
        }
    }

    /// Test that a device record that cannot be encoded is the plugin store's `codingError`, and that an
    /// error of any other type is still an engine credential store error
    ///
    /// - Given: the client's encoding failure (an `EncodingError` under `unknown`), and a body throwing an
    ///   error that is neither a client nor an engine error
    /// - When:
    ///    - each is mapped
    /// - Then:
    ///    - the encoding failure is `codingError`, with the client's error underneath
    ///    - the foreign error is `unknown`, with it underneath; an engine error passes through unchanged
    ///
    func testEncodingAndForeignFailuresAreEngineErrors() async {
        let encoding = AuthClientError.unknown(
            "Could not encode the value.",
            "bug",
            EncodingError.invalidValue(Double.nan, .init(codingPath: [], debugDescription: "NaN"))
        )
        guard case .codingError(_, let underlying) = ClientCredentialStore.engineError(for: encoding) else {
            return XCTFail("an encoding failure should be codingError")
        }
        XCTAssertNotNil(underlying as? AuthClientError)

        do {
            try await ClientCredentialStore.mappingStorageErrors { throw FixtureError(description: "foreign") }
            XCTFail("did not throw")
        } catch EngineCredentialStoreError.unknown(_, let underlying) {
            XCTAssertTrue(underlying is FixtureError)
        } catch {
            XCTFail("expected unknown, got \(error)")
        }
        await assertThrows(.itemNotFound) {
            try await ClientCredentialStore.mappingStorageErrors { throw EngineCredentialStoreError.itemNotFound }
        }
    }

    private func assertThrows(
        _ expected: EngineCredentialStoreError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ body: () async throws -> Void
    ) async {
        do {
            try await body()
            XCTFail("did not throw", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? EngineCredentialStoreError, expected, file: file, line: line)
        }
    }
}
