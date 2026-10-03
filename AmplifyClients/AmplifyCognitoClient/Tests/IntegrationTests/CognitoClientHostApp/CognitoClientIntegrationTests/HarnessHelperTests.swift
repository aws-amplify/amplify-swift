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

    /// The CI-only skip (`IntegrationTestEnvironment.skipOnCIIfMissing`) happens only on CI, off the sandbox's
    /// file set, with the resource missing, for every reason (offline).
    ///
    /// - Given: Every `CISkipReason`, and each of the 8 combinations of the three conditions: the run is CI's
    ///   (`COGNITO_CLIENT_INTEG_CI_SKIPS=1`), the file set is the sandbox's, the resource is present
    /// - When:
    ///    - The helper is called over each combination
    /// - Then:
    ///    - It throws `XCTSkip`, with the reason's message, for exactly one combination: on CI, off the sandbox's
    ///      set, the resource missing; for the other seven it returns, and the decision without throwing
    ///      (`skipsOnCI`) agrees
    ///    - The file set is not read unless the run is CI's and the resource is missing
    ///    - Each message says it is a CI-only skip, and no two reasons share one
    ///    - With the conditions read from this process, a present resource never skips, and, off CI (no
    ///      variable, as in every local run), neither does a missing one
    ///    - Of the sign-up roles, only the device-alias one has a CI skip (`SandboxSignUp.ciSkip(for:)`), with
    ///      `deviceAliasConfirmation`
    ///
    func testCISkipHappensOnlyOnCIOffTheSandboxWithTheResourceMissing() throws {
        for reason in CISkipReason.allCases {
            for isCIRun in [false, true] {
                for isSandboxFileSet in [false, true] {
                    for present in [false, true] {
                        let combination = "\(reason), CI \(isCIRun), sandbox \(isSandboxFileSet), present \(present)"
                        let expected = isCIRun && !isSandboxFileSet && !present
                        var fileSetRead = false
                        let fileSet = {
                            fileSetRead = true
                            return isSandboxFileSet
                        }
                        do {
                            try IntegrationTestEnvironment.skipOnCIIfMissing(
                                reason,
                                present: present,
                                isCIRun: isCIRun,
                                isSandboxFileSet: fileSet()
                            )
                            XCTAssertFalse(expected, "\(combination): returned, but should skip")
                        } catch let skip as XCTSkip {
                            XCTAssertTrue(expected, "\(combination): skipped, but should return")
                            XCTAssertEqual(skip.message, reason.message, combination)
                        }
                        XCTAssertEqual(fileSetRead, isCIRun && !present, "\(combination): file set read")
                        XCTAssertEqual(
                            IntegrationTestEnvironment.skipsOnCI(
                                present: present,
                                isCIRun: isCIRun,
                                isSandboxFileSet: isSandboxFileSet
                            ),
                            expected,
                            combination
                        )
                    }
                }
            }

            XCTAssertTrue(reason.message.hasPrefix("Skipped on CI: the plugin's "), "\(reason)")
            XCTAssertNoThrow(try IntegrationTestEnvironment.skipOnCIIfMissing(reason, present: true), "\(reason)")
            XCTAssertFalse(IntegrationTestEnvironment.skipsOnCI(present: true), "\(reason)")
            if !IntegrationTestEnvironment.isCIRun {
                XCTAssertNoThrow(try IntegrationTestEnvironment.skipOnCIIfMissing(reason, present: false), "\(reason)")
                XCTAssertFalse(IntegrationTestEnvironment.skipsOnCI(present: false), "\(reason)")
            }
        }
        XCTAssertEqual(Set(CISkipReason.allCases.map(\.message)).count, CISkipReason.allCases.count)
        XCTAssertEqual(CISkipReason.allCases.count, 6)

        for pool in SandboxPool.allCases {
            let skip = SandboxSignUp.ciSkip(for: pool)
            if pool == .emailAlias {
                XCTAssertEqual(skip?.reason, .deviceAliasConfirmation, "\(pool)")
            } else {
                XCTAssertNil(skip, "\(pool): only the device-alias role's sign-ups skip on CI")
            }
        }
    }
}

extension HarnessHelperTests {

    /// A fresh sign-up whose SDK retry met `UsernameExistsException` (CH-4) adopts the earlier attempt's user
    /// when it signs in with this call's password, confirming it first when it is unconfirmed and can be.
    ///
    /// - Given: `resolveAcceptedSignUp(canConfirm:probe:confirm:)` over fake probes and a fake confirm, no request
    /// - When:
    ///    - The probe signs in at once
    ///    - The probe finds the user unconfirmed, the user can be confirmed, and the probe after the confirm
    ///      signs in
    /// - Then:
    ///    - Both adopt the user with the sub its access token names, the second saying it confirmed it first
    ///    - The first probes once and never confirms; the second confirms once, between its two probes
    ///
    func testAnAcceptedSignUpIsAdoptedWhenItSignsInWithThisCallsPassword() async throws {
        var calls: [String] = []
        let atOnce = try await SandboxSignUp.resolveAcceptedSignUp(
            canConfirm: true,
            probe: {
                calls.append("probe")
                return .signedIn(userSub: "sub-sentinel")
            },
            confirm: { calls.append("confirm") }
        )
        XCTAssertEqual(atOnce, .adopt(userSub: "sub-sentinel", afterConfirming: false))
        XCTAssertEqual(calls, ["probe"])

        calls = []
        var probes: [SandboxSignUp.AcceptedSignUpProbe] = [.unconfirmed, .signedIn(userSub: "sub-sentinel")]
        let afterConfirming = try await SandboxSignUp.resolveAcceptedSignUp(
            canConfirm: true,
            probe: {
                calls.append("probe")
                return probes.removeFirst()
            },
            confirm: { calls.append("confirm") }
        )
        XCTAssertEqual(afterConfirming, .adopt(userSub: "sub-sentinel", afterConfirming: true))
        XCTAssertEqual(calls, ["probe", "confirm", "probe"])
    }

    /// An accepted sign-up whose sub cannot be learned without changing the user is replaced, and a failed
    /// confirm or probe fails the sign-up.
    ///
    /// - Given: `resolveAcceptedSignUp(canConfirm:probe:confirm:)` over fake probes and a fake confirm, no request
    /// - When:
    ///    - The probe meets a challenge
    ///    - The probe finds the user unconfirmed, and it cannot be confirmed (left for the confirm step, or on
    ///      `email-alias`)
    ///    - The user is confirmed, and the probe after it meets a challenge
    ///    - The confirm throws
    /// - Then:
    ///    - The first three replace the user; only the third confirms
    ///    - The last throws the confirm's error
    ///
    func testAnAcceptedSignUpIsReplacedWhenItCannotBeAdopted() async throws {
        var confirms = 0
        let challenged = try await SandboxSignUp.resolveAcceptedSignUp(
            canConfirm: true,
            probe: { .challenged },
            confirm: { confirms += 1 }
        )
        XCTAssertEqual(challenged, .replace)
        XCTAssertEqual(confirms, 0)

        let leftUnconfirmed = try await SandboxSignUp.resolveAcceptedSignUp(
            canConfirm: false,
            probe: { .unconfirmed },
            confirm: { confirms += 1 }
        )
        XCTAssertEqual(leftUnconfirmed, .replace)
        XCTAssertEqual(confirms, 0)

        var probes: [SandboxSignUp.AcceptedSignUpProbe] = [.unconfirmed, .challenged]
        let challengedAfterConfirming = try await SandboxSignUp.resolveAcceptedSignUp(
            canConfirm: true,
            probe: { probes.removeFirst() },
            confirm: { confirms += 1 }
        )
        XCTAssertEqual(challengedAfterConfirming, .replace)
        XCTAssertEqual(confirms, 1)

        struct ConfirmFailed: Error {}
        do {
            _ = try await SandboxSignUp.resolveAcceptedSignUp(
                canConfirm: true,
                probe: { .unconfirmed },
                confirm: { throw ConfirmFailed() }
            )
            XCTFail("A failed confirm was not thrown")
        } catch is ConfirmFailed {
            // Expected.
        }
    }

    /// `probeAcceptedSignUp` reads a password sign-in's first step as an earlier attempt's user, and fails
    /// when the user refuses this call's password.
    ///
    /// - Given: Fake first steps, no request: tokens whose access token names a sub, a challenge,
    ///   `UserNotConfirmedException`, `NotAuthorizedException`, `UserNotFoundException`, and tokens whose
    ///   access token names no sub
    /// - When:
    ///    - Each is probed
    /// - Then:
    ///    - Tokens are `.signedIn` with the sub, a challenge `.challenged`, and `UserNotConfirmedException`
    ///      `.unconfirmed`
    ///    - Both refusals throw `notThisCallsUserMessage`; tokens with no sub throw too
    ///
    func testAProbeOfAnAcceptedSignUpReadsTheFirstStep() async throws {
        func step(accessToken: String?, challenge: Bool = false) -> RawSignInStep {
            RawSignInStep(InitiateAuthOutput(
                authenticationResult: challenge ? nil : .init(accessToken: accessToken),
                challengeName: challenge ? .mfaSetup : nil
            ))
        }
        func token(_ claims: [String: Any]) throws -> String {
            let payload = try JSONSerialization.data(withJSONObject: claims, options: .sortedKeys)
                .base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
            return "eyJhbGciOiJub25lIn0.\(payload).sig"
        }
        let signedIn = try token(["sub": "sub-sentinel", "token_use": "access"])
        let noSub = try token(["token_use": "access"])

        let probed = try await SandboxSignUp.probeAcceptedSignUp { step(accessToken: signedIn) }
        XCTAssertEqual(probed, .signedIn(userSub: "sub-sentinel"))
        let challenged = try await SandboxSignUp.probeAcceptedSignUp { step(accessToken: nil, challenge: true) }
        XCTAssertEqual(challenged, .challenged)
        let unconfirmed = try await SandboxSignUp.probeAcceptedSignUp { throw UserNotConfirmedException(message: "User is not confirmed.") }
        XCTAssertEqual(unconfirmed, .unconfirmed)

        let refusals: [any Error] = [
            NotAuthorizedException(message: "Incorrect username or password."),
            UserNotFoundException(message: "User does not exist.")
        ]
        for refusal in refusals {
            do {
                _ = try await SandboxSignUp.probeAcceptedSignUp { throw refusal }
                XCTFail("\(type(of: refusal)) was taken for this call's user")
            } catch let error as HarnessError {
                XCTAssertEqual(error.description, SandboxSignUp.notThisCallsUserMessage, "\(type(of: refusal))")
            }
        }
        do {
            _ = try await SandboxSignUp.probeAcceptedSignUp { step(accessToken: noSub) }
            XCTFail("Tokens naming no sub were taken for a signed-in user")
        } catch is HarnessError {
            // Expected.
        }
    }
}

extension HarnessHelperTests {

    /// Errors other than the ones `probeAcceptedSignUp` reads, from the sign-in or from `resolveAcceptedSignUp`'s
    /// probe, reach the sign-up unchanged; a sign-up replaces an earlier attempt's user once, no more; and an
    /// `email-alias` user whose sub is unknown is not discarded.
    ///
    /// - Given: A sign-in that throws a transport error and one that throws `InvalidParameterException`, a probe
    ///   that throws a transport error, both values of `mayReplace`, and earlier attempts' users on two roles,
    ///   with and without a sub; no request
    /// - When:
    ///    - Each is run
    /// - Then:
    ///    - The probe and the decision rethrow each error as it was
    ///    - `requireReplaceable` returns for the first replacement and throws for a second
    ///    - Only the `email-alias` user without a sub is left undiscarded
    ///
    func testAnAcceptedSignUpPassesOtherErrorsOnAndIsReplacedOnce() async throws {
        do {
            _ = try await SandboxSignUp.probeAcceptedSignUp { throw URLError(.timedOut) }
            XCTFail("A transport error was swallowed")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .timedOut)
        }
        do {
            _ = try await SandboxSignUp.probeAcceptedSignUp { throw InvalidParameterException() }
            XCTFail("InvalidParameterException was swallowed")
        } catch is InvalidParameterException {
            // Expected: its type is what is checked (the SDK's initializer does not keep the message).
        }
        do {
            _ = try await SandboxSignUp.resolveAcceptedSignUp(
                canConfirm: true,
                probe: { throw URLError(.networkConnectionLost) },
                confirm: {}
            )
            XCTFail("A failed probe was swallowed")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .networkConnectionLost)
        }

        XCTAssertNoThrow(try SandboxSignUp.requireReplaceable(true, on: .standard))
        XCTAssertThrowsError(try SandboxSignUp.requireReplaceable(false, on: .standard)) { error in
            XCTAssertTrue(error is HarnessError, "\(error)")
        }

        func earlier(_ pool: SandboxPool, sub: String) -> FreshUser {
            FreshUser(
                pool: pool, username: "ccit-sentinel", password: "unused", email: nil, phoneNumber: nil,
                userSub: sub, isConfirmed: false
            )
        }
        XCTAssertTrue(SandboxSignUp.discards(earlier(.standard, sub: "")))
        XCTAssertTrue(SandboxSignUp.discards(earlier(.emailAlias, sub: "sub-sentinel")))
        XCTAssertFalse(SandboxSignUp.discards(earlier(.emailAlias, sub: "")))
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
