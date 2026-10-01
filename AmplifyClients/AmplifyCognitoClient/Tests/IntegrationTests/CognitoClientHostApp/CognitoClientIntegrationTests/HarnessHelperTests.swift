//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import AmplifyFoundation
import AWSCognitoIdentityProvider
import Foundation
import Security
import XCTest

/// The shared helpers behave as the suites rely on.
final class HarnessHelperTests: ClientIntegrationTestCase {

    /// `TOTP.code` is RFC 6238 with HMAC-SHA1, 30-second steps and 6 digits.
    ///
    /// - Given: The RFC 6238 appendix B SHA-1 secret, `12345678901234567890`, in base32
    /// - When:
    ///    - Codes are computed at the appendix's times
    /// - Then:
    ///    - Each is the last 6 digits of the appendix's 8-digit value
    ///
    func testTOTPMatchesTheRFC6238Vectors() throws {
        let secret = TOTPSecret("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ")
        let vectors: [(TimeInterval, String)] = [
            (59, "287082"),
            (1_111_111_109, "081804"),
            (1_234_567_890, "005924"),
            (2_000_000_000, "279037")
        ]
        for (time, expected) in vectors {
            XCTAssertEqual(try TOTP.code(secret: secret, at: Date(timeIntervalSince1970: time)), expected, "at \(time)")
        }
    }

    /// `freshCode` never hands out two codes from the same step, across runs as well.
    ///
    /// - Given: A code source over a fake clock stopped 20 s into a step, and a store holding no step
    /// - When:
    ///    - Two codes are requested without the clock moving
    ///    - A second source over the same store (the next run) requests one
    /// - Then:
    ///    - The first is the current step's code, with no wait
    ///    - The second waits once, until just past the next step starts, and is that step's code
    ///    - The next run's source reads the stored step and waits for the step after it
    ///
    func testFreshCodeNeverReusesAStep() async throws {
        let secret = TOTPSecret("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ")
        // Step 34 runs from 1 020 s to 1 050 s.
        let clock = FakeClock(Date(timeIntervalSince1970: 1_040))
        let stored = StoredStep()
        let store = TOTP.LastStepStore(load: { stored.value }, save: { stored.value = $0 })
        let source = TOTP.FreshCodeSource(now: { clock.now }, sleep: { clock.advance($0) }, lastStepStore: store)

        let first = try await source.freshCode(secret: secret)
        let second = try await source.freshCode(secret: secret)
        let nextRun = TOTP.FreshCodeSource(now: { clock.now }, sleep: { clock.advance($0) }, lastStepStore: store)
        let third = try await nextRun.freshCode(secret: secret)

        XCTAssertEqual(first, try TOTP.code(secret: secret, step: 34))
        XCTAssertEqual(second, try TOTP.code(secret: secret, step: 35))
        XCTAssertEqual(third, try TOTP.code(secret: secret, step: 36))
        XCTAssertEqual(clock.sleeps, [10.5, 30.0])
        XCTAssertEqual(stored.value, 36)
    }

    /// A stored step ahead of the clock is clamped, not waited on forever.
    ///
    /// - Given: A store holding a step 100 steps ahead of a fake clock stopped 20 s into step 34
    /// - When:
    ///    - A code is requested
    /// - Then:
    ///    - The source treats step 34 as spent: it waits once, just past the start of step 35, and
    ///      returns step 35's code
    ///    - The store now holds 35
    ///
    func testFreshCodeClampsAStoredStepAheadOfTheClock() async throws {
        let secret = TOTPSecret("GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ")
        let clock = FakeClock(Date(timeIntervalSince1970: 1_040))
        let stored = StoredStep()
        stored.value = 134
        let store = TOTP.LastStepStore(load: { stored.value }, save: { stored.value = $0 })
        let source = TOTP.FreshCodeSource(now: { clock.now }, sleep: { clock.advance($0) }, lastStepStore: store)

        let code = try await source.freshCode(secret: secret)

        XCTAssertEqual(code, try TOTP.code(secret: secret, step: 35))
        XCTAssertEqual(clock.sleeps, [10.5])
        XCTAssertEqual(stored.value, 35)
    }

    /// `uniqueSessionID` tags the ID and never repeats one.
    ///
    /// - Given: One tag
    /// - When:
    ///    - Two session IDs are minted from it
    /// - Then:
    ///    - Both are `<tag>-<8 lowercase hex digits>`, and they differ
    ///
    func testUniqueSessionIDsAreTaggedAndDistinct() throws {
        let first = try IntegrationTestEnvironment.uniqueSessionID("alice")
        let second = try IntegrationTestEnvironment.uniqueSessionID("alice")

        for sessionId in [first, second] {
            XCTAssertNotNil(
                sessionId.stringValue.range(of: "^alice-[0-9a-f]{8}$", options: .regularExpression),
                sessionId.stringValue
            )
        }
        XCTAssertNotEqual(first, second)
    }

    /// The code reader retires a `listMfaInfo` form only for a schema refusal before any form answered, and
    /// never lets go of the form that answered (`ListMfaInfoForms`, offline).
    ///
    /// - Given: AppSync's untyped validation and type-mismatch errors, and typed transient ones
    /// - When:
    ///    - The errors are classified, and three APIs' forms are driven: the sandbox's (a transient error on
    ///      `listMfaInfo(username:)` after it answered, then a validation error on the argument-less one), a
    ///      plugin backend's (both forms refused by the schema), and one whose first form fails transiently
    ///      before anything answered
    /// - Then:
    ///    - Only untyped errors are schema refusals
    ///    - The sandbox's API keeps asking `listMfaInfo(username:)` alone; the plugin backend's asks nothing;
    ///      the transient failure leaves both forms to be asked again
    ///
    func testListMfaInfoFormsRetireOnlyASchemaRefusalBeforeAnyAnswer() {
        let validation: [String: Any] = ["message": "Validation error of type FieldUndefined: Field 'x' is undefined"]
        let mismatch: [String: Any] = ["message": "Can't resolve value (/listMfaInfo) : type mismatch error"]
        XCTAssertTrue(ListMfaInfoForms.isSchemaRefusal([validation]))
        XCTAssertTrue(ListMfaInfoForms.isSchemaRefusal([validation, mismatch]))
        for type in ["UnauthorizedException", "DynamoDB:ProvisionedThroughputExceededException", "InternalFailure"] {
            XCTAssertFalse(ListMfaInfoForms.isSchemaRefusal([["errorType": type, "message": "m"]]), type)
            XCTAssertFalse(ListMfaInfoForms.isSchemaRefusal([validation, ["errorType": type]]), type)
        }
        XCTAssertFalse(ListMfaInfoForms.isSchemaRefusal([]))

        var sandbox = ListMfaInfoForms()
        XCTAssertEqual(sandbox.toAsk, [true, false])
        sandbox.answered(true)
        sandbox.refused(true, byTheSchema: false)
        sandbox.refused(true, byTheSchema: true)
        sandbox.refused(false, byTheSchema: true)
        sandbox.answered(false)
        XCTAssertEqual(sandbox.toAsk, [true], "the form that answered is kept, whatever fails later")

        var plugin = ListMfaInfoForms()
        plugin.refused(true, byTheSchema: true)
        XCTAssertEqual(plugin.toAsk, [false])
        plugin.refused(false, byTheSchema: true)
        XCTAssertEqual(plugin.toAsk, [], "a backend that answers neither form is read from the subscription alone")

        var flaky = ListMfaInfoForms()
        flaky.refused(true, byTheSchema: false)
        XCTAssertEqual(flaky.toAsk, [true, false], "a transient failure retires nothing")
    }

    /// `jwtClaims` decodes a base64url payload, including the characters base64url replaces.
    ///
    /// - Given: A three-segment token whose payload encodes to `-` and `_` and needs padding
    /// - When:
    ///    - Its claims are decoded, and a two-segment string is decoded
    /// - Then:
    ///    - The claims round-trip; the malformed string throws
    ///
    func testJWTClaimsDecodesTheBase64URLPayload() throws {
        let claims: [String: Any] = ["sub": "abc", "username": "alice", "blob": "??>>~~", "iat": 1_700_000_000]
        let payload = try JSONSerialization.data(withJSONObject: claims, options: .sortedKeys)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        XCTAssertTrue(payload.contains("-") || payload.contains("_"), "The fixture no longer exercises base64url")

        let decoded = try IntegrationTestEnvironment.jwtClaims("eyJhbGciOiJub25lIn0.\(payload).sig")

        XCTAssertEqual(decoded["sub"] as? String, "abc")
        XCTAssertEqual(decoded["username"] as? String, "alice")
        XCTAssertEqual(decoded["blob"] as? String, "??>>~~")
        XCTAssertEqual(decoded["iat"] as? Int, 1_700_000_000)
        XCTAssertThrowsError(try IntegrationTestEnvironment.jwtClaims("a.b"))
    }

    /// `rawKeychainAccounts` lists a service, scoped to an access group when one is given.
    ///
    /// - Given: A unique service holding two accounts in the default group and one in the shared group
    /// - When:
    ///    - It is listed with each group, and with none
    /// - Then:
    ///    - Each scoped listing returns exactly that group's accounts, sorted; the unscoped one returns all three
    ///
    func testRawKeychainAccountsListsOneServiceScopedToAGroup() throws {
        let service = "com.amplify.cognitoClient.integration.helper.\(UUID().uuidString)"
        let defaultGroup = try IntegrationTestEnvironment.defaultAccessGroup()
        let sharedGroup = try IntegrationTestEnvironment.sharedAccessGroup()
        defer {
            for group in [defaultGroup, sharedGroup] {
                SecItemDelete([
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                    kSecAttrAccessGroup as String: group,
                    kSecUseDataProtectionKeychain as String: true
                ] as CFDictionary)
            }
        }
        for (account, group) in [("b", defaultGroup), ("a", defaultGroup), ("c", sharedGroup)] {
            let status = SecItemAdd([
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrAccessGroup as String: group,
                kSecValueData as String: Data(),
                kSecUseDataProtectionKeychain as String: true
            ] as CFDictionary, nil)
            XCTAssertEqual(status, errSecSuccess)
        }

        XCTAssertEqual(try IntegrationTestEnvironment.rawKeychainAccounts(service: service, accessGroup: defaultGroup), ["a", "b"])
        XCTAssertEqual(try IntegrationTestEnvironment.rawKeychainAccounts(service: service, accessGroup: sharedGroup), ["c"])
        XCTAssertEqual(try IntegrationTestEnvironment.rawKeychainAccounts(service: service), ["a", "b", "c"])
    }

    /// `RecordingHTTPClient`, installed through `configureUserPoolClient`, sees each request's target
    /// and the final user agent.
    ///
    /// - Given: A client whose user pool SDK client has the recorder installed through the escape hatch
    /// - When:
    ///    - `GetUser` is sent through `getUserPoolClient()` with an invalid access token
    /// - Then:
    ///    - Cognito rejects the call
    ///    - The recorder saw exactly one request, `GetUser`, whose `User-Agent` already carries the
    ///      client's `lib/amplify-swift#<version>` and `md/amplify-cognito#<version>`. So the recorder
    ///      sits inside the user-agent engine, which is what the user-agent test needs
    ///
    func testRecordingHTTPClientSeesTheTargetAndTheFinalUserAgent() async throws {
        let recorder = RecordingHTTPClient()
        let client = try AmplifyCognitoClient(
            configuration: IntegrationTestEnvironment.configuration(),
            options: .init(sessionId: makeSessionID("recorder"), configureUserPoolClient: recorder.configureUserPoolClient)
        )
        let userPool = try XCTUnwrap(client.getUserPoolClient())

        do {
            _ = try await userPool.getUser(input: GetUserInput(accessToken: "not-a-token"))
            XCTFail("GetUser accepted an invalid access token")
        } catch {
            // Expected: any service error. Only the recorded request matters here.
        }

        XCTAssertEqual(recorder.operations, ["GetUser"])
        let userAgent = try XCTUnwrap(recorder.requests.first?.userAgent)
        let version = AmplifyMetadata.version
        XCTAssertTrue(userAgent.contains("lib/\(AmplifyMetadata.platformName)#\(version)"), userAgent)
        XCTAssertTrue(userAgent.contains("md/amplify-cognito#\(version)"), userAgent)
    }

    /// `SessionCleanup` releases a session and leaves no row for it.
    ///
    /// - Given: A client over a fresh session, read once and then dropped
    /// - When:
    ///    - `SessionCleanup.cleanUp` runs for it
    /// - Then:
    ///    - The registry holds no live session for it
    ///    - The session store has no account for it, in any group
    ///
    func testCleanUpReleasesTheSessionAndLeavesNoRow() async throws {
        let configuration = try IntegrationTestEnvironment.configuration()
        let sessionId = try makeSessionID("cleanup")
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: sessionId))
            let state = await client.currentSessionState()
            XCTAssertEqual(state, .signedOut)
        }

        try await SessionCleanup.cleanUp([CreatedSession(sessionId: sessionId, accessGroup: nil)], configuration: configuration)

        XCTAssertNil(SessionCoreRegistry.shared.liveSession(for: sessionId))
        let accounts = try IntegrationTestEnvironment.rawKeychainAccounts()
        XCTAssertFalse(accounts.contains { $0.contains(".\(sessionId.stringValue).") }, RealKeychain.redact("\(accounts)"))
    }
}

extension HarnessHelperTests {

    /// `SessionCleanup` is best effort: one session's failure does not stop the others' cleanup.
    ///
    /// - Given: Two sessions, the first in an access group the app is not entitled to (so its sign-out
    ///   cannot read storage), the second an ordinary one that was read once and dropped
    /// - When:
    ///    - `SessionCleanup.cleanUp` runs for both, the failing one first
    /// - Then:
    ///    - It throws the first session's `AuthClientError`
    ///    - The second session was still cleaned up: it is not live, and it has no row
    ///
    func testCleanUpContinuesPastAFailingSession() async throws {
        let configuration = try IntegrationTestEnvironment.configuration()
        let notEntitled = try IntegrationTestEnvironment.defaultAccessGroup()
            .replacingOccurrences(of: "CognitoClientHostApp", with: "NotEntitled")
        // Not minted through makeSessionID: tearDown would fail on it again.
        let failing = CreatedSession(
            sessionId: try IntegrationTestEnvironment.uniqueSessionID("cleanup-fails"),
            accessGroup: notEntitled
        )
        let ordinary = try makeSessionID("cleanup-ok")
        do {
            let client = try AmplifyCognitoClient(configuration: configuration, options: .init(sessionId: ordinary))
            _ = await client.currentSessionState()
        }

        do {
            try await SessionCleanup.cleanUp(
                [failing, CreatedSession(sessionId: ordinary, accessGroup: nil)],
                configuration: configuration
            )
            XCTFail("Cleanup of a session in a group the app is not entitled to succeeded")
        } catch {
            XCTAssertTrue(error is AuthClientError, "\(error)")
        }

        XCTAssertNil(SessionCoreRegistry.shared.liveSession(for: ordinary))
        let accounts = try IntegrationTestEnvironment.rawKeychainAccounts()
        XCTAssertFalse(accounts.contains { $0.contains(".\(ordinary.stringValue).") }, RealKeychain.redact("\(accounts)"))
    }
}

/// A stored step shared by two code sources, standing in for the host app's defaults.
private final class StoredStep: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: UInt64?

    var value: UInt64? {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }
}

/// A clock that only moves when the code source sleeps.
private final class FakeClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    private var recordedSleeps: [TimeInterval] = []

    init(_ start: Date) {
        self.current = start
    }

    var now: Date {
        lock.withLock { current }
    }

    var sleeps: [TimeInterval] {
        lock.withLock { recordedSleeps }
    }

    func advance(_ seconds: TimeInterval) {
        lock.withLock {
            recordedSleeps.append(seconds)
            current = current.addingTimeInterval(seconds)
        }
    }
}
