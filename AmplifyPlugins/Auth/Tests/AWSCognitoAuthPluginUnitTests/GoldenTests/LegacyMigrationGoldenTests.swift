//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain
import XCTest
@testable import Amplify
@_spi(KeychainStore) @testable import AWSPluginsCore
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// Part of the stored-format gate: the legacy AWSMobileClient keychain records still migrate to the same
/// values.
///
/// Each `GoldenStoredFormat/AWSMobileClient/<name>.seed.json` is a hand-written set of legacy records, keyed
/// by the exact service names `MigrateLegacyCredentialStore` reads (including the
/// `Optional("<bundle>").AWSMobileClient` quirk). `<bundle>` stands for `Bundle.main.bundleIdentifier`.
/// The seed is served through the injectable `legacyKeychainStoreFactory`, the action runs, and what it
/// writes to the new store, what it clears and what it reads are compared with `<name>.migrated.json`,
/// recorded with the baselines. The migrated session is also compared field by field with `migrations.json`.
///
/// Since the credential store moved into the engine, the seeds go through the `KeychainItemStoreBehavior`
/// fake instead; the recorded results must not change.
@available(*, deprecated, message: "Exercises deprecated token and flow APIs, on purpose")
final class LegacyMigrationGoldenTests: XCTestCase {

    static var directory: URL {
        GoldenFiles.directory("GoldenStoredFormat").appendingPathComponent("AWSMobileClient", isDirectory: true)
    }

    // MARK: Seed and result model

    struct Seed: Codable {
        struct Value: Codable {
            let string: String?
            let data: String?
            /// An `OSStatus` the read fails with, as `EngineCredentialStoreError.securityError`.
            let error: Int32?
        }

        let summary: String
        let authConfiguration: String
        /// `absent`, `present`, or `securityError`: what the new store's `retrieveCredential()` does.
        let existingSession: String
        let services: [String: [String: Value]]
    }

    /// What the migration did, with every service name written back with the `<bundle>` placeholder.
    struct Result: Codable, Equatable {
        let event: String
        /// The saved `AmplifyCredentials`, as JSON text in canonical form, or `nil` if nothing was saved.
        let savedCredentials: String?
        let savedDevices: [String: String]
        let savedASFDevices: [String: String]
        let clearedServices: [String]
        /// Every legacy read, in order, as `<service> | <key>`.
        let reads: [String]
    }

    struct MigrationsManifest: Codable {
        struct Entry: Codable {
            let name: String
            let summary: String
            /// `FieldDump` of the migrated `AmplifyCredentials`, or empty if none was saved.
            let credentialFields: [String: String]
        }

        let note: String
        let bundlePlaceholder: String
        let migrations: [Entry]
    }

    static var configurations: [String: AuthConfiguration] {
        let fixtures = StoredFormatFixtures.self
        return [
            "userPools-minimal": .userPools(fixtures.minimalUserPool),
            "identityPools": .identityPools(fixtures.identityPool),
            "userPoolsAndIdentityPools-minimal": .userPoolsAndIdentityPools(fixtures.minimalUserPool, fixtures.identityPool),
            "userPoolsAndIdentityPools-full": .userPoolsAndIdentityPools(fixtures.fullUserPool, fixtures.identityPool)
        ]
    }

    static func seedNames() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasSuffix(".seed.json") }
            .map { String($0.dropLast(".seed.json".count)) }
            .sorted()
    }

    // MARK: Tests

    /// Test that every AWSMobileClient seed set migrates exactly as it did when the baseline was recorded
    ///
    /// - Given: Each legacy seed set, served through `legacyKeychainStoreFactory`
    /// - When:
    ///    - `MigrateLegacyCredentialStore` runs against an empty new store
    /// - Then:
    ///    - The saved session, devices and ASF ids, the cleared services, the reads and the event are
    ///      tree-equal to the recorded result
    ///    - The saved session's fields equal the ones in `migrations.json`
    ///
    func testLegacySeedSetsMigrateAsRecorded() async throws {
        let bundle = try XCTUnwrap(Bundle.main.bundleIdentifier, "The migration needs a bundle identifier")
        let names = try Self.seedNames()
        XCTAssertGreaterThanOrEqual(names.count, 10)

        var entries: [MigrationsManifest.Entry] = []
        for name in names {
            let seed = try JSONDecoder().decode(
                Seed.self,
                from: Data(contentsOf: Self.directory.appendingPathComponent("\(name).seed.json"))
            )
            let (result, credentials) = try await Self.migrate(seed, bundle: bundle)
            let resultURL = Self.directory.appendingPathComponent("\(name).migrated.json")
            let fields = credentials.map { FieldDump.fields(of: $0) } ?? [:]
            entries.append(.init(name: name, summary: seed.summary, credentialFields: fields))

            if GoldenFiles.isGenerating {
                try GoldenFiles.write(GoldenFiles.snapshotData(result), to: resultURL)
                continue
            }
            let recorded = try Data(contentsOf: resultURL)
            let current = try GoldenFiles.snapshotData(result)
            XCTAssertTrue(
                try CanonicalJSON.areEqual(current, recorded),
                "\(name): migrated\n\(String(decoding: current, as: UTF8.self))\nrecorded\n\(String(decoding: recorded, as: UTF8.self))"
            )
        }

        let manifestURL = Self.directory.appendingPathComponent("migrations.json")
        if GoldenFiles.isGenerating {
            let manifest = MigrationsManifest(
                note: "Recorded at M2 step S0b by running MigrateLegacyCredentialStore over each seed set. Never regenerate.",
                bundlePlaceholder: "<bundle>",
                migrations: entries
            )
            try GoldenFiles.write(GoldenFiles.snapshotData(manifest), to: manifestURL)
            return
        }
        let manifest = try JSONDecoder().decode(MigrationsManifest.self, from: Data(contentsOf: manifestURL))
        XCTAssertEqual(manifest.migrations.map(\.name), entries.map(\.name))
        for (recorded, current) in zip(manifest.migrations, entries) {
            assertFields(current.credentialFields, recorded.credentialFields, "\(recorded.name) migrated session")
        }
    }

    // MARK: Running one seed set

    static func migrate(_ seed: Seed, bundle: String) async throws -> (Result, AmplifyCredentials?) {
        let authConfiguration = try XCTUnwrap(configurations[seed.authConfiguration], seed.authConfiguration)
        let legacy = SeededLegacyKeychain(seed: seed, bundle: bundle)
        let store = CapturingCredentialStore(existingSession: seed.existingSession)
        let environment = CredentialEnvironment(
            authConfiguration: authConfiguration,
            credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                amplifyCredentialStoreFactory: { store },
                legacyKeychainStoreFactory: { legacy.store(service: $0) }
            ),
            logger: AmplifyEngineLogRouter(scope: .category("awsCognitoAuthPluginTest"))
        )
        let events = EventBox()
        await MigrateLegacyCredentialStore().execute(
            withDispatcher: MockDispatcher { events.append($0) },
            environment: environment
        )

        let credentials = store.savedCredentials
        let result = try Result(
            event: events.names.joined(separator: ", "),
            savedCredentials: credentials.map {
                try String(decoding: CanonicalJSON.canonicalize(JSONEncoder().encode($0)), as: UTF8.self)
            },
            savedDevices: store.savedDevices.mapValues {
                try String(decoding: CanonicalJSON.canonicalize(JSONEncoder().encode($0)), as: UTF8.self)
            },
            savedASFDevices: store.savedASFDevices,
            clearedServices: legacy.cleared.map { legacy.placeholder($0) },
            reads: legacy.reads.map { "\(legacy.placeholder($0.service)) | \($0.key)" }
        )
        return (result, credentials)
    }
}

// MARK: Fakes

/// The legacy keychain, served from a seed set. Records every read and every `_removeAll`.
private final class SeededLegacyKeychain: @unchecked Sendable {
    private let lock = NSLock()
    private let bundle: String
    private var services: [String: [String: LegacyMigrationGoldenTests.Seed.Value]]
    private var recordedReads: [(service: String, key: String)] = []
    private var recordedClears: [String] = []

    init(seed: LegacyMigrationGoldenTests.Seed, bundle: String) {
        self.bundle = bundle
        self.services = Dictionary(uniqueKeysWithValues: seed.services.map {
            ($0.key.replacingOccurrences(of: "<bundle>", with: bundle), $0.value)
        })
    }

    var reads: [(service: String, key: String)] { locked { recordedReads } }
    var cleared: [String] { locked { recordedClears } }

    func placeholder(_ service: String) -> String {
        service.replacingOccurrences(of: bundle, with: "<bundle>")
    }

    func store(service: String) -> any KeychainItemStoreBehavior {
        SeededLegacyStore(keychain: self, service: service)
    }

    func read(service: String, key: String) throws -> Data {
        try locked {
            recordedReads.append((service, key))
            guard let value = services[service]?[key] else {
                throw EngineCredentialStoreError.itemNotFound
            }
            if let status = value.error {
                throw EngineCredentialStoreError.securityError(status)
            }
            return Data((value.string ?? value.data ?? "").utf8)
        }
    }

    func removeAll(service: String) {
        locked {
            recordedClears.append(service)
            services[service] = nil
        }
    }

    func hasItems(service: String) -> Bool {
        locked { !(services[service] ?? [:]).isEmpty }
    }

    private func locked<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

private struct SeededLegacyStore: LegacyKeychainItemStoreDouble, @unchecked Sendable {
    let keychain: SeededLegacyKeychain
    let service: String

    func getData(_ key: String) throws -> Data {
        try keychain.read(service: service, key: key)
    }

    func set(_ value: Data, key: String) throws {
        XCTFail("The migration must not write to a legacy store")
    }

    func remove(_ key: String) throws {
        XCTFail("The migration removes legacy stores only with removeAll")
    }

    func removeAll() throws {
        keychain.removeAll(service: service)
    }

    func hasItems() throws -> Bool {
        keychain.hasItems(service: service)
    }
}

/// The new credential store: records what the migration saves.
private final class CapturingCredentialStore: AmplifyAuthCredentialStoreBehavior, @unchecked Sendable {
    private let lock = NSLock()
    private let existingSession: String
    private var credentials: AmplifyCredentials?
    private var devices: [String: DeviceMetadata] = [:]
    private var asfDevices: [String: String] = [:]

    init(existingSession: String) {
        self.existingSession = existingSession
    }

    var savedCredentials: AmplifyCredentials? { locked { credentials } }
    var savedDevices: [String: DeviceMetadata] { locked { devices } }
    var savedASFDevices: [String: String] { locked { asfDevices } }

    func saveCredential(_ credential: AmplifyCredentials) throws {
        locked { credentials = credential }
    }

    func retrieveCredential() throws -> AmplifyCredentials {
        switch existingSession {
        case "present":
            return StoredFormatFixtures.presentSession
        case "securityError":
            throw EngineCredentialStoreError.securityError(errSecInteractionNotAllowed)
        default:
            throw EngineCredentialStoreError.itemNotFound
        }
    }

    func deleteCredential() throws {}

    func saveDevice(_ deviceMetadata: DeviceMetadata, for username: String) throws {
        locked { devices[username] = deviceMetadata }
    }

    func retrieveDevice(for username: String) throws -> DeviceMetadata {
        throw EngineCredentialStoreError.itemNotFound
    }

    func removeDevice(for username: String) throws {}

    func saveASFDevice(_ deviceId: String, for username: String) throws {
        locked { asfDevices[username] = deviceId }
    }

    func retrieveASFDevice(for username: String) throws -> String {
        throw EngineCredentialStoreError.itemNotFound
    }

    func removeASFDevice(for username: String) throws {}

    private func locked<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

/// Collects dispatched events' case names.
final class EventBox: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [String] = []

    func append(_ event: StateMachineEvent) {
        let name: String = if let event = event as? CredentialStoreEvent {
            FieldDump.caseName(of: event.eventType)
        } else {
            event.type
        }
        lock.lock()
        recorded.append(name)
        lock.unlock()
    }

    var names: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }
}

extension StoredFormatFixtures {
    /// A session already in the new store, for the "newer session exists" path.
    static var presentSession: AmplifyCredentials {
        .identityPoolOnly(identityID: identityID, credentials: engineCredentials)
    }
}
