//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

final class LazyUserPoolAnalyticsTests: XCTestCase {

    private static let service = "com.amazonaws.AWSPinpointContext"
    private static let account = "com.amazonaws.AWSPinpointContextKeychainUniqueIdKey"
    private static let appId = "pinpoint-app"

    private var keychain: TestKeychain!
    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var applicationSupport: URL!
    private var directoryReads: CallCounter!

    override func setUpWithError() throws {
        keychain = TestKeychain()
        suiteName = "LazyUserPoolAnalyticsTests.\(UUID().uuidString)"
        userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        applicationSupport = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName)
        directoryReads = CallCounter()
    }

    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: suiteName)
        if FileManager.default.fileExists(atPath: applicationSupport.path) {
            try FileManager.default.removeItem(at: applicationSupport)
        }
    }

    private func analytics(
        pinpointAppId: String? = LazyUserPoolAnalyticsTests.appId,
        queue: DispatchQueue = DispatchQueue(label: "test.analytics-io")
    ) -> LazyUserPoolAnalytics {
        let directory = applicationSupport
        let reads = directoryReads!
        return LazyUserPoolAnalytics(
            pinpointAppId: pinpointAppId,
            keychain: keychain.itemStore(service: Self.service),
            userDefaults: userDefaults,
            applicationSupportDirectory: {
                reads.increment()
                return directory
            },
            queue: queue
        )
    }

    /// Asks for the metadata as the engine does, once per request.
    private func resolved(_ analytics: LazyUserPoolAnalytics) async -> String? {
        await analytics.analyticsMetadata()?.analyticsEndpointId
    }

    // MARK: Fixtures for the three sources

    private func storeInKeychain(_ endpointId: String) {
        keychain.put(Data(endpointId.utf8), Self.account, service: Self.service)
    }

    private var preferencesFile: URL {
        LazyUserPoolAnalytics.legacyPreferencesFile(in: applicationSupport, pinpointAppId: Self.appId)
    }

    private func writePreferences(_ json: String, appId: String = LazyUserPoolAnalyticsTests.appId) throws {
        let file = LazyUserPoolAnalytics.legacyPreferencesFile(in: applicationSupport, pinpointAppId: appId)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(json.utf8).write(to: file)
    }

    /// Everything the three sources hold, to compare before and after.
    private struct Snapshot: Equatable {
        let keychainValue: Data?
        let defaults: [String: String]
        let files: [String: Data]
    }

    private func snapshot() throws -> Snapshot {
        var files: [String: Data] = [:]
        if let enumerator = FileManager.default.enumerator(at: applicationSupport, includingPropertiesForKeys: nil) {
            for case let url as URL in enumerator where !url.hasDirectoryPath {
                files[url.path] = try Data(contentsOf: url)
            }
        }
        let defaults = (userDefaults.persistentDomain(forName: suiteName) ?? [:]).compactMapValues { $0 as? String }
        return Snapshot(keychainValue: keychain.value(service: Self.service, account: Self.account), defaults: defaults, files: files)
    }

    private var touchedAccounts: [String] {
        keychain.readAccounts + keychain.writtenAccounts + keychain.removedAccounts
    }

    // MARK: Keys

    /// The keys and the preferences path are `PinpointContext`'s.
    ///
    /// - Given: `InternalAWSPinpoint`'s `PinpointContext.Constants`
    /// - When:
    ///    - they are compared with the client's
    /// - Then:
    ///    - the keychain service and account, the UserDefaults key and the preferences path are equal, literally
    ///
    func testKeysArePinpointContextsConstants() {
        XCTAssertEqual(LazyUserPoolAnalytics.pinpointContextService, "com.amazonaws.AWSPinpointContext")
        XCTAssertEqual(LazyUserPoolAnalytics.endpointIdAccount, "com.amazonaws.AWSPinpointContextKeychainUniqueIdKey")
        XCTAssertEqual(LazyUserPoolAnalytics.legacyPreferencesUniqueIdKey, "UniqueId")
        XCTAssertEqual(
            LazyUserPoolAnalytics.legacyPreferencesFile(in: URL(fileURLWithPath: "/AppSupport"), pinpointAppId: "abc123").path,
            "/AppSupport/com.amazonaws.MobileAnalytics/abc123/preferences"
        )
    }

    // MARK: No I/O

    /// Without a Pinpoint app ID, analytics reads nothing at all.
    ///
    /// - Given: analytics with a `nil` app ID, and with an empty one, over a keychain that fails every
    ///   operation, with an ID in every source
    /// - When:
    ///    - it is created and asked for metadata
    /// - Then:
    ///    - the metadata is `nil`; the keychain saw no call and the preferences directory was never asked for
    ///
    func testNoPinpointAppIdDoesNoIO() async throws {
        storeInKeychain("keychain-id")
        try writePreferences(#"{"UniqueId":"preferences-id"}"#)
        userDefaults.set("defaults-id", forKey: Self.account)
        keychain.failing(.read, with: errSecIO)
        for appId in [nil, ""] as [String?] {
            let analytics = analytics(pinpointAppId: appId)
            let metadata = await analytics.analyticsMetadata()
            XCTAssertFalse(analytics.isEnabled)
            XCTAssertNil(metadata)
        }
        XCTAssertEqual(touchedAccounts, [])
        XCTAssertEqual(directoryReads.count, 0)
    }

    /// Creating analytics reads nothing, and neither does reading its cache; only a request's
    /// `analyticsMetadata()` does.
    ///
    /// - Given: a Pinpoint app ID and an ID stored in the keychain
    /// - When:
    ///    - analytics is created, and its cached endpoint ID is read before any request
    /// - Then:
    ///    - the cached ID is `nil`, and no source was read
    ///
    func testInitAndCacheReadDoNoIO() {
        storeInKeychain("keychain-id")
        let analytics = analytics()

        XCTAssertNil(analytics.endpointId)
        XCTAssertEqual(touchedAccounts, [])
        XCTAssertEqual(directoryReads.count, 0)
    }

    // MARK: Each source, read only

    /// The keychain's ID wins, and nothing is written.
    ///
    /// - Given: different IDs in the keychain, the preferences file and UserDefaults
    /// - When:
    ///    - analytics is asked for metadata twice
    /// - Then:
    ///    - the metadata is the keychain's ID; no source changed; the second request read nothing
    ///
    func testKeychainIdIsUsed() async throws {
        storeInKeychain("keychain-id")
        try writePreferences(#"{"UniqueId":"preferences-id"}"#)
        userDefaults.set("defaults-id", forKey: Self.account)
        let before = try snapshot()
        let analytics = analytics()

        let first = await resolved(analytics)
        XCTAssertEqual(first, "keychain-id")
        keychain.resetLogs()
        let second = await resolved(analytics)
        XCTAssertEqual(second, "keychain-id")

        XCTAssertEqual(touchedAccounts, [])
        XCTAssertEqual(try snapshot(), before)
        XCTAssertFalse(keychain.hasMutations)
    }

    /// With nothing in the keychain, the legacy preferences file's ID is used, and nothing is migrated.
    ///
    /// - Given: an empty keychain, a preferences file for this app ID, and an ID in UserDefaults
    /// - When:
    ///    - analytics is asked for metadata
    /// - Then:
    ///    - the metadata is the preferences file's ID
    ///    - the keychain is not written, the file is not removed, and UserDefaults is unchanged
    ///
    func testLegacyPreferencesIdIsUsed() async throws {
        try writePreferences(#"{"UniqueId":"preferences-id","Other":"value"}"#)
        userDefaults.set("defaults-id", forKey: Self.account)
        let before = try snapshot()

        let id = await resolved(analytics())

        XCTAssertEqual(id, "preferences-id")
        XCTAssertEqual(try snapshot(), before)
        XCTAssertTrue(FileManager.default.fileExists(atPath: preferencesFile.path))
        XCTAssertFalse(keychain.hasMutations)
    }

    /// With nothing in the keychain or the preferences file, UserDefaults' ID is used, and left in place.
    ///
    /// - Given: an empty keychain, a preferences file for **another** app ID, and an ID in UserDefaults
    /// - When:
    ///    - analytics is asked for metadata
    /// - Then:
    ///    - the metadata is UserDefaults' ID; the keychain is not written and UserDefaults still holds it
    ///
    func testUserDefaultsIdIsUsed() async throws {
        try writePreferences(#"{"UniqueId":"other-app-id"}"#, appId: "other-app")
        userDefaults.set("defaults-id", forKey: Self.account)
        let before = try snapshot()

        let id = await resolved(analytics())

        XCTAssertEqual(id, "defaults-id")
        XCTAssertEqual(userDefaults.string(forKey: Self.account), "defaults-id")
        XCTAssertEqual(try snapshot(), before)
        XCTAssertFalse(keychain.hasMutations)
    }

    /// With no ID anywhere, no endpoint ID is sent, and none is created.
    ///
    /// - Given: an empty keychain, no preferences file and nothing in UserDefaults
    /// - When:
    ///    - analytics is asked for metadata twice
    /// - Then:
    ///    - the metadata is `nil`; nothing was written anywhere; the second request read nothing
    ///
    func testNoIdFoundSendsNoMetadata() async throws {
        let analytics = analytics()

        let first = await resolved(analytics)
        XCTAssertNil(first)
        XCTAssertEqual(keychain.readAccounts, [Self.account])
        keychain.resetLogs()
        let second = await resolved(analytics)
        XCTAssertNil(second)

        XCTAssertEqual(touchedAccounts, [])
        XCTAssertFalse(keychain.hasMutations)
        XCTAssertNil(userDefaults.persistentDomain(forName: suiteName)?[Self.account])
        XCTAssertFalse(FileManager.default.fileExists(atPath: applicationSupport.path))
        XCTAssertEqual(directoryReads.count, 1)
    }

    /// A keychain value that is not a string falls through to the next source, as `PinpointContext`'s does,
    /// and is left alone.
    ///
    /// - Given: bytes in the keychain that are not UTF-8, and an ID in UserDefaults
    /// - When:
    ///    - analytics is asked for metadata
    /// - Then:
    ///    - the metadata is UserDefaults' ID, and the keychain value is unchanged
    ///
    func testUnreadableKeychainValueFallsThrough() async throws {
        keychain.put(Data([0xff, 0xfe]), Self.account, service: Self.service)
        userDefaults.set("defaults-id", forKey: Self.account)
        let before = try snapshot()

        let id = await resolved(analytics())

        XCTAssertEqual(id, "defaults-id")
        XCTAssertEqual(try snapshot(), before)
    }

    /// A malformed preferences file is not an ID.
    ///
    /// - Given: an empty keychain, a preferences file that is not a JSON object of strings, and an ID in UserDefaults
    /// - When:
    ///    - analytics is asked for metadata
    /// - Then:
    ///    - the metadata is UserDefaults' ID, and the file is unchanged
    ///
    func testMalformedPreferencesFileIsSkipped() async throws {
        try writePreferences(#"{"UniqueId":42}"#)
        userDefaults.set("defaults-id", forKey: Self.account)
        let before = try snapshot()

        let id = await resolved(analytics())

        XCTAssertEqual(id, "defaults-id")
        XCTAssertEqual(try snapshot(), before)
    }

    // MARK: A keychain failure is not "absent"

    /// A failed keychain read does not fall through, is not cached, and writes nothing.
    ///
    /// - Given: keychain reads failing with `errSecInteractionNotAllowed`, and IDs in the preferences file and UserDefaults
    /// - When:
    ///    - analytics is asked for metadata; then the failure clears and it is asked again
    /// - Then:
    ///    - the first metadata is `nil`: neither the file's nor UserDefaults' ID is used, and nothing changed
    ///    - the second resolves to the keychain's ID
    ///
    func testKeychainReadFailureIsNotAbsent() async throws {
        storeInKeychain("keychain-id")
        try writePreferences(#"{"UniqueId":"preferences-id"}"#)
        userDefaults.set("defaults-id", forKey: Self.account)
        let before = try snapshot()
        keychain.failingReads(of: Self.account, with: errSecInteractionNotAllowed)
        let analytics = analytics()

        let first = await resolved(analytics)
        XCTAssertNil(first)
        XCTAssertEqual(directoryReads.count, 0)
        XCTAssertEqual(try snapshot(), before)

        keychain.clearFailures()
        let second = await resolved(analytics)
        XCTAssertEqual(second, "keychain-id")
    }

    // MARK: Concurrency

    /// A lookup stuck in the keychain holds no lock: the cache read returns at once, and other requests
    /// wait on the shared lookup, not on a lock.
    ///
    /// - Given: an ID in the keychain, and a keychain read that blocks until released
    /// - When:
    ///    - one request is started and reaches the read; the cache is then read, and a second request is
    ///      started
    /// - Then:
    ///    - the cache read returns `nil` while the lookup is blocked
    ///    - once released, both requests get the keychain's ID, after one read
    ///
    func testStuckLookupHoldsNoLock() async {
        storeInKeychain("keychain-id")
        let reached = DispatchSemaphore(value: 0)
        let release = DispatchSemaphore(value: 0)
        keychain.onceAfterReading(Self.account) {
            reached.signal()
            release.wait()
        }
        let analytics = analytics()

        let first = Task { await analytics.resolvedEndpointId() }
        await Self.wait(for: reached)
        XCTAssertNil(analytics.endpointId)
        let second = Task { await analytics.resolvedEndpointId() }
        release.signal()
        let firstId = await first.value
        let secondId = await second.value

        XCTAssertEqual(firstId, "keychain-id")
        XCTAssertEqual(secondId, "keychain-id")
        XCTAssertEqual(keychain.readAccounts, [Self.account])
    }

    /// The lookup does its I/O on analytics' own queue, not on the caller's thread.
    ///
    /// - Given: an ID in the keychain, and a hook recording whether the read runs on the analytics queue
    /// - When:
    ///    - `analyticsMetadata()` is awaited
    /// - Then:
    ///    - the read ran on that queue
    ///
    func testLookupRunsOnItsQueue() async {
        storeInKeychain("keychain-id")
        let queue = DispatchQueue(label: "test.analytics-io")
        let key = DispatchSpecificKey<Bool>()
        queue.setSpecific(key: key, value: true)
        let onQueue = Flag()
        let offQueue = Flag()
        keychain.afterEveryRead(of: Self.account) {
            DispatchQueue.getSpecific(key: key) == true ? onQueue.raise() : offQueue.raise()
        }

        let id = await resolved(analytics(queue: queue))
        XCTAssertEqual(id, "keychain-id")
        XCTAssertTrue(onQueue.isRaised)
        XCTAssertFalse(offQueue.isRaised)
    }

    /// Concurrent first callers share one lookup.
    ///
    /// - Given: an ID in UserDefaults only
    /// - When:
    ///    - 20 tasks ask for the metadata at once
    /// - Then:
    ///    - all get that ID, from one keychain read and one preferences lookup
    ///
    func testConcurrentFirstCallersResolveOnce() async {
        userDefaults.set("defaults-id", forKey: Self.account)
        let analytics = analytics()

        let ids = await withTaskGroup(of: String?.self) { group in
            for _ in 0 ..< 20 {
                group.addTask {
                    await analytics.analyticsMetadata()?.analyticsEndpointId
                }
            }
            return await group.reduce(into: Set<String?>()) { $0.insert($1) }
        }

        XCTAssertEqual(ids, ["defaults-id"])
        XCTAssertEqual(keychain.readAccounts, [Self.account])
        XCTAssertEqual(directoryReads.count, 1)
        XCTAssertFalse(keychain.hasMutations)
    }

    /// Waits for `semaphore` on a Dispatch thread, so no cooperative thread blocks.
    private static func wait(for semaphore: DispatchSemaphore) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                semaphore.wait()
                continuation.resume()
            }
        }
    }
}
