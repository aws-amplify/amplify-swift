//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth

/// One engine operation's session credentials, in memory only.
///
/// Seeded with the payload the core handed the operation, and read back when the operation ends. The engine
/// writes and clears it through `ClientCredentialStore`; it never reaches the keychain. The core then does the
/// commit-guarded write of the record, as it always has.
///
/// The payload is decoded and encoded with a default `JSONDecoder()` / `JSONEncoder()`, the plugin store's
/// coder (`AWSCognitoAuthCredentialStore.encode` / `decode`), so a payload stays decode-compatible with the
/// plugin's `AmplifyCredentials` and the frozen `*.payload.json` fixtures. The bytes are not deterministic
/// (dictionary order), so compare decoded values, never bytes.
///
/// `@unchecked Sendable`: `value` is only read or assigned while holding `lock`.
final class CredentialSlot: @unchecked Sendable {

    enum Value: Equatable {
        /// Not written or cleared by the engine yet: the seed, or `nil` for no credentials.
        case untouched(AmplifyCredentials?)
        case written(AmplifyCredentials)
        case cleared
    }

    /// What an operation hands back to the core.
    enum Outcome: Equatable {
        /// The engine did not write or clear the credentials.
        case unchanged
        /// The engine wrote new credentials: the payload to commit.
        case written(Data)
        /// The engine removed the credentials.
        case cleared
    }

    private let lock = NSLock()
    private var value: Value

    /// A slot seeded with `seed`. `.noCredentials` is stored as no credentials, so the engine reads it as
    /// absent (`itemNotFound`), exactly like a `nil` seed.
    init(seed: AmplifyCredentials?) {
        self.value = .untouched(seed == .noCredentials ? nil : seed)
    }

    /// A slot seeded with a payload, decoded with the plugin store's coder. `nil` means no credentials.
    ///
    /// - Throws: the decoding error, if the payload is not an `AmplifyCredentials`.
    convenience init(payload: Data?) throws {
        try self.init(seed: payload.map(Self.decode))
    }

    var current: Value {
        withLock { value }
    }

    /// The credentials the engine sees now, or `nil` for none.
    var credentials: AmplifyCredentials? {
        switch current {
        case .untouched(let credentials):
            return credentials
        case .written(let credentials):
            return credentials
        case .cleared:
            return nil
        }
    }

    func write(_ credentials: AmplifyCredentials) {
        withLock { value = .written(credentials) }
    }

    func clear() {
        withLock { value = .cleared }
    }

    /// Replaces the seed, if the engine has neither written nor cleared the slot yet: a pending sign-in whose
    /// session became a guest meanwhile continues from the guest's credentials.
    func reseed(_ credentials: AmplifyCredentials?) {
        withLock {
            if case .untouched = value {
                value = .untouched(credentials == .noCredentials ? nil : credentials)
            }
        }
    }

    /// What the operation returns: the written payload, encoded with the plugin store's coder, a removal,
    /// or no change.
    func outcome() throws -> Outcome {
        switch current {
        case .untouched:
            return .unchanged
        case .written(let credentials):
            return try .written(Self.encode(credentials))
        case .cleared:
            return .cleared
        }
    }

    /// The plugin store's decoder: a default `JSONDecoder()`.
    static func decode(_ payload: Data) throws -> AmplifyCredentials {
        try JSONDecoder().decode(AmplifyCredentials.self, from: payload)
    }

    /// The plugin store's encoder: a default `JSONEncoder()`.
    static func encode(_ credentials: AmplifyCredentials) throws -> Data {
        try JSONEncoder().encode(credentials)
    }

    /// A payload's user pool tokens alone, `userPoolOnly(signedInData:)`, dropping any identity ID and AWS
    /// credentials; `nil` for a payload with no user pool tokens. What a record carried forward from a
    /// user pool namespace keeps (`SessionRecordStore.readCarryingForward`): an identity from another identity
    /// pool, or from none, is never carried.
    ///
    /// - Throws: the decoding error, if the payload is not an `AmplifyCredentials`.
    @Sendable
    static func userPoolTokensOnly(_ payload: Data) throws -> Data? {
        switch try decode(payload) {
        case .userPoolOnly:
            return payload
        case .userPoolAndIdentityPool(let signedInData, _, _):
            return try encode(.userPoolOnly(signedInData: signedInData))
        case .identityPoolOnly, .identityPoolWithFederation, .noCredentials:
            return nil
        }
    }

    /// A payload's identity pool identity ID, or `nil` if it names none or is not an `AmplifyCredentials`: how
    /// the storage layer tells two guests or federated identities apart (`SessionRecordStore+CopyForward.swift`).
    @Sendable
    static func identityId(_ payload: Data) -> String? {
        switch try? decode(payload) {
        case .userPoolAndIdentityPool(_, let identityId, _)?,
             .identityPoolOnly(let identityId, _)?,
             .identityPoolWithFederation(_, let identityId, _)?:
            return identityId
        case .userPoolOnly?, .noCredentials?, nil:
            return nil
        }
    }

    /// A payload's user pool refresh token, or `nil` if it holds none or is not an `AmplifyCredentials`: how a sign-out
    /// tells whether a copy it sweeps holds a refresh token it has not revoked (`SessionRecordStore.copiesToRevoke`).
    @Sendable
    static func refreshToken(_ payload: Data) -> String? {
        switch try? decode(payload) {
        case .userPoolOnly(let signedInData)?, .userPoolAndIdentityPool(let signedInData, _, _)?:
            return signedInData.cognitoUserPoolTokens.refreshToken
        case .identityPoolOnly?, .identityPoolWithFederation?, .noCredentials?, nil:
            return nil
        }
    }

    private func withLock<Result>(_ body: () -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}

/// The engine's credential store, as the client provides it: the plugin's
/// `AWSCognitoAuthCredentialStore` is never constructed.
///
/// It splits the engine's store in two:
/// - **Session credentials** live in the operation's `CredentialSlot`, in memory. The engine has no path to
///   the keychain for them, so it can never write the plugin's `amplify.<poolNamespace>.session` key, the
///   client's `amplify.1.…` records or `authConfiguration`. Absent credentials are `itemNotFound`, never a
///   failure: `InitializeAuthConfiguration` then takes its "No existing session found." branch.
/// - **Device and advanced-security records** are per user, shared by every session of a namespace, at the
///   plugin's keys, through `DeviceRecordIO`, which runs each keychain call on its own queue,
///   off the cooperative pool.
///
/// A `DeviceRecordStore` read maps onto the engine's errors as the plugin's store reports them:
/// `.absent` is `itemNotFound`; `.undecodable` is the coding error the plugin's `decode`
/// throws; a keychain failure (`storageUnavailable`) is the engine's keychain failure, **never**
/// `itemNotFound`.
///
/// `@unchecked Sendable`: every stored property is immutable, and the slot and the I/O queue are
/// thread-safe themselves.
final class ClientCredentialStore: AmplifyAuthCredentialStoreBehavior, @unchecked Sendable {

    let slot: CredentialSlot
    let devices: DeviceRecordIO

    init(slot: CredentialSlot, devices: DeviceRecordIO) {
        self.slot = slot
        self.devices = devices
    }

    // MARK: Session credentials: the slot

    func saveCredential(_ credential: AmplifyCredentials) throws {
        slot.write(credential)
    }

    func retrieveCredential() throws -> AmplifyCredentials {
        guard let credentials = slot.credentials else {
            throw EngineCredentialStoreError.itemNotFound
        }
        return credentials
    }

    func deleteCredential() throws {
        slot.clear()
    }

    // MARK: Device metadata and the ASF device ID: the per-user records

    func saveDevice(_ deviceMetadata: DeviceMetadata, for username: String) async throws {
        try await Self.mappingStorageErrors {
            try await devices.saveDeviceMetadata(deviceMetadata, for: username)
        }
    }

    func retrieveDevice(for username: String) async throws -> DeviceMetadata {
        let read = try await Self.mappingStorageErrors {
            try await devices.deviceMetadata(DeviceMetadata.self, for: username)
        }
        return try Self.value(of: read)
    }

    func removeDevice(for username: String) async throws {
        try await Self.mappingStorageErrors {
            try await devices.removeDeviceMetadata(for: username)
        }
    }

    func saveASFDevice(_ deviceId: String, for username: String) async throws {
        try await Self.mappingStorageErrors {
            try await devices.saveASFDeviceId(deviceId, for: username)
        }
    }

    func retrieveASFDevice(for username: String) async throws -> String {
        let read = try await Self.mappingStorageErrors {
            try await devices.asfDeviceId(for: username)
        }
        return try Self.value(of: read)
    }

    func removeASFDevice(for username: String) async throws {
        try await Self.mappingStorageErrors {
            try await devices.removeASFDeviceId(for: username)
        }
    }

    // MARK: Error mapping

    /// `.absent` is the plugin store's `itemNotFound`; `.undecodable` is the coding error its `decode` throws.
    static func value<Value>(of read: DeviceRecordStore.Read<Value>) throws -> Value {
        switch read {
        case .value(let value):
            return value
        case .absent:
            throw EngineCredentialStoreError.itemNotFound
        case .undecodable:
            throw EngineCredentialStoreError.codingError("Error occurred while decoding the stored value", nil)
        }
    }

    /// Rethrows every failure as an engine credential store error, never `itemNotFound`: a client storage
    /// failure as the engine's keychain failure, and anything else as `unknown` with it underneath, so no
    /// error type the engine does not know escapes.
    static func mappingStorageErrors<Result>(_ body: () async throws -> Result) async throws -> Result {
        do {
            return try await body()
        } catch let error as AuthClientError {
            throw engineError(for: error)
        } catch let error as EngineCredentialStoreError {
            throw error
        } catch {
            throw EngineCredentialStoreError.unknown(String(describing: error), error)
        }
    }

    /// The engine error for a client storage failure. A keychain status keeps its `securityError`; a value
    /// that could not be encoded is the `codingError` the plugin's store throws; anything else is `unknown`,
    /// with the client's error underneath. `itemNotFound` is never produced here: an absent record is a
    /// `Read`, not an error.
    static func engineError(for error: AuthClientError) -> EngineCredentialStoreError {
        if error.underlyingError is EncodingError {
            return .codingError("Error occurred while encoding the value", error)
        }
        switch error.underlyingError as? KeychainAccessError {
        case .securityError(let status):
            return .securityError(status)
        case .unknown(let description, let underlying):
            return .unknown(description, underlying)
        case .itemNotFound, nil:
            return .unknown(error.errorDescription, error)
        }
    }
}
