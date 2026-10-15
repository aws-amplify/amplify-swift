//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCloudWatchLoggingPlugin

import Amplify
import CryptoKit
import XCTest
@testable import AmplifyTestCommon

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class AWSCloudWatchLoggingCategoryClientTests: XCTestCase, @unchecked Sendable {
    let category = "categoryclienttests"
    let authentication = ControlledCurrentUserAuth()
    var systemUnderTest: AWSCloudWatchLoggingCategoryClient!

    override func setUp() async throws {
        let configuration = AWSCloudWatchLoggingPluginConfiguration(logGroupName: "logGroupName", region: "us-east-1")
        systemUnderTest = AWSCloudWatchLoggingCategoryClient(
            enable: true,
            credentialIdentityResolver: MockCredentialsProvider(),
            authentication: authentication,
            loggingConstraintsResolver: AWSCloudWatchLoggingConstraintsResolver(loggingPluginConfiguration: configuration),
            logGroupName: "logGroupName",
            region: "us-east-1",
            localStoreMaxSizeInMB: 1,
            flushIntervalInSeconds: 3_600,
            networkMonitor: MockLoggingNetworkMonitor()
        )
    }

    override func tearDown() async throws {
        systemUnderTest = nil
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        try? FileManager.default.removeItem(at: documents.appendingPathComponent("amplify").appendingPathComponent("logging"))
    }

    /// Loggers for one category
    ///
    /// - Given: a category client
    /// - When:
    ///    - loggers for one category are requested with different log levels
    /// - Then:
    ///    - they're the same controller, so a single session writes the category's log directory
    ///
    func testLoggersForOneCategoryShareController() {
        let errorLogger = systemUnderTest.logger(forCategory: category, logLevel: .error)
        let debugLogger = systemUnderTest.logger(forCategory: category, logLevel: .debug)
        XCTAssertTrue(errorLogger as AnyObject === debugLogger as AnyObject)
    }

    /// A user lookup that a later auth event superseded
    ///
    /// - Given: a category client with a logger
    /// - When:
    ///    - a sign-in starts a user lookup, the user signs out, and then the lookup returns a user
    /// - Then:
    ///    - the stale result is ignored, while a later lookup still switches the logger to its user
    ///
    func testStaleUserLookupDoesNotOverrideSignOut() async throws {
        let staleUser = "user-\(UUID().uuidString)"
        let currentUser = "user-\(UUID().uuidString)"
        _ = systemUnderTest.logger(forCategory: category, logLevel: .error)

        systemUnderTest.handle(payload: HubPayload(eventName: HubPayload.EventName.Auth.signedIn))
        let started = await waitUntil { await self.authentication.pendingLookups == 1 }
        XCTAssertTrue(started)
        systemUnderTest.handle(payload: HubPayload(eventName: HubPayload.EventName.Auth.signedOut))
        await authentication.resolveOldestLookup(with: staleUser)

        let switchedToStaleUser = await waitUntil(timeout: 1) { self.logDirectoryExists(forUser: staleUser) }
        XCTAssertFalse(switchedToStaleUser, "A lookup that a later auth event superseded shouldn't change the user")

        systemUnderTest.handle(payload: HubPayload(eventName: HubPayload.EventName.Auth.signedIn))
        let restarted = await waitUntil { await self.authentication.pendingLookups == 1 }
        XCTAssertTrue(restarted)
        await authentication.resolveOldestLookup(with: currentUser)
        let switchedToCurrentUser = await waitUntil { self.logDirectoryExists(forUser: currentUser) }
        XCTAssertTrue(switchedToCurrentUser, "The latest lookup should switch the logger to its user")
    }

    /// Mirrors the directory `AWSCloudWatchLoggingSession` derives for a signed-in user.
    private func logDirectoryExists(forUser userIdentifier: String) -> Bool {
        let digest = SHA256.hash(data: Data(userIdentifier.utf8))
        let normalized = digest.map { String(format: "%02X", $0) }.joined()
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directory = documents.appendingPathComponent("amplify")
                                 .appendingPathComponent("logging")
                                 .appendingPathComponent(normalized)
                                 .appendingPathComponent(category)
        return FileManager.default.fileExists(atPath: directory.path)
    }
}

/// Each `getCurrentUser()` call waits until the test resolves it, oldest first.
final class ControlledCurrentUserAuth: MockAuthCategoryPlugin, @unchecked Sendable {
    private let lookups = PendingLookups()

    var pendingLookups: Int {
        get async { await lookups.count }
    }

    func resolveOldestLookup(with userIdentifier: String?) async {
        await lookups.resolveOldest(with: userIdentifier)
    }

    override func getCurrentUser() async throws -> any AuthUser {
        guard let userIdentifier = await lookups.wait() else {
            throw AuthError.signedOut("No user is signed in", "")
        }
        return TestUser(username: userIdentifier, userId: userIdentifier)
    }
}

private actor PendingLookups {
    private var continuations: [CheckedContinuation<String?, Never>] = []

    var count: Int { continuations.count }

    func wait() async -> String? {
        await withCheckedContinuation { continuations.append($0) }
    }

    func resolveOldest(with userIdentifier: String?) {
        continuations.removeFirst().resume(returning: userIdentifier)
    }
}

private struct TestUser: AuthUser {
    let username: String
    let userId: String
}
