//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Dispatch
import Foundation

/// The device record store, with every blocking keychain call moved off Swift's cooperative thread pool —
/// the same mechanism as `SessionRecordIO`, and for the same reason.
///
/// One per engine, so per session core, with its own serial queue: one session's stuck device-record call
/// never delays another session's. Device records are shared by the sessions of one namespace, but each
/// call is one keychain operation, so no cross-session ordering is needed beyond the keychain's own.
struct DeviceRecordIO: Sendable {

    static func makeQueue() -> DispatchQueue {
        DispatchQueue(label: "com.amazonaws.amplify.cognito-client.device-record-io")
    }

    let store: DeviceRecordStore
    let queue: DispatchQueue

    init(store: DeviceRecordStore, queue: DispatchQueue = DeviceRecordIO.makeQueue()) {
        self.store = store
        self.queue = queue
    }

    /// Runs `work` against the store on the I/O queue; the caller suspends until it returns.
    func perform<T: Sendable>(_ work: @escaping @Sendable (DeviceRecordStore) throws -> T) async throws -> T {
        let store = store
        return try await runBlocking(on: queue) { try work(store) }
    }

    func deviceMetadata<Metadata: Decodable & Sendable>(
        _ type: Metadata.Type,
        for username: String
    ) async throws -> DeviceRecordStore.Read<Metadata> {
        try await perform { try $0.deviceMetadata(type, for: username) }
    }

    func saveDeviceMetadata(_ metadata: some Encodable & Sendable, for username: String) async throws {
        try await perform { try $0.saveDeviceMetadata(metadata, for: username) }
    }

    func removeDeviceMetadata(for username: String) async throws {
        try await perform { try $0.removeDeviceMetadata(for: username) }
    }

    func asfDeviceId(for username: String) async throws -> DeviceRecordStore.Read<String> {
        try await perform { try $0.asfDeviceId(for: username) }
    }

    func saveASFDeviceId(_ deviceId: String, for username: String) async throws {
        try await perform { try $0.saveASFDeviceId(deviceId, for: username) }
    }

    func removeASFDeviceId(for username: String) async throws {
        try await perform { try $0.removeASFDeviceId(for: username) }
    }
}
