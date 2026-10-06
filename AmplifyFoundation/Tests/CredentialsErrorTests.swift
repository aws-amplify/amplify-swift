//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyFoundation

final class CredentialsErrorTests: XCTestCase {

    /// A signed-out session is permanent for that session, so buffered work is worthless.
    ///
    /// - Given: a `notSignedIn` failure
    /// - When: a consumer asks what to do
    /// - Then:
    ///    - the disposition is `.discard`
    func testNotSignedInDiscards() {
        let error = CredentialsError.notSignedIn("signed out", "sign in first")
        XCTAssertEqual(error.disposition, .discard)
    }

    /// An expired refresh token is recoverable, so buffered work must survive.
    ///
    /// - Given: a `sessionExpired` failure
    /// - When: a consumer asks what to do
    /// - Then:
    ///    - the disposition is `.retryAfterReauthentication`, never `.discard`
    func testSessionExpiredRetainsBuffer() {
        let error = CredentialsError.sessionExpired("expired", "sign in again")
        XCTAssertEqual(error.disposition, .retryAfterReauthentication)
        XCTAssertNotEqual(error.disposition, .discard)
    }

    /// A locked device resolves itself. Treating it as signed-out is the bug this type exists
    /// to prevent, so assert it explicitly rather than relying on the switch reading correctly.
    ///
    /// - Given: `storageUnavailable` with `.locked` and with `.interrupted`
    /// - When: a consumer asks what to do
    /// - Then:
    ///    - both retry with backoff, and neither discards
    func testTransientStorageFailuresRetry() {
        for reason in [StorageUnavailableReason.locked, .interrupted] {
            let error = CredentialsError.storageUnavailable(reason, "unreadable", "retry")
            XCTAssertEqual(error.disposition, .retryWithBackoff, "\(reason) must retry")
            XCTAssertNotEqual(error.disposition, .discard, "\(reason) must not discard")
        }
    }

    /// A misconfiguration will never resolve on its own, so burying it in a retry loop hides it.
    ///
    /// - Given: `storageUnavailable` with `.denied`
    /// - When: a consumer asks what to do
    /// - Then:
    ///    - the disposition is `.failLoudly`
    func testDeniedStorageFailsLoudly() {
        let error = CredentialsError.storageUnavailable(.denied, "no entitlement", "fix the access group")
        XCTAssertEqual(error.disposition, .failLoudly)
    }

    /// A provider asked for a credential it cannot produce in this configuration will never succeed on retry,
    /// so it must surface rather than loop.
    ///
    /// - Given: a `notConfigured` failure, e.g. AWS credentials from a session with no identity pool
    /// - When: a consumer asks what to do
    /// - Then:
    ///    - the disposition is `.failLoudly`, never a retry or a discard
    func testNotConfiguredFailsLoudly() {
        let error = CredentialsError.notConfigured("no identity pool", "configure an identity pool")
        XCTAssertEqual(error.disposition, .failLoudly)
    }

    /// An unrecognised failure must not cost data. This pins the cautious default so a future
    /// case cannot quietly start discarding buffered work.
    ///
    /// - Given: an `unknown` failure
    /// - When: a consumer asks what to do
    /// - Then:
    ///    - the disposition retries rather than discards
    func testUnknownIsCautious() {
        let error = CredentialsError.unknown("no idea", "none")
        XCTAssertEqual(error.disposition, .retryWithBackoff)
        XCTAssertNotEqual(error.disposition, .discard)
    }

    /// - Given: each case carrying a description, suggestion and underlying error
    /// - When: read through the `AmplifyError` conformance
    /// - Then:
    ///    - all three are returned, for every case including the one with an extra payload
    func testAmplifyErrorConformanceReadsAllCases() {
        struct Underlying: Error {}
        let cases: [CredentialsError] = [
            .notSignedIn("d1", "r1", Underlying()),
            .sessionExpired("d2", "r2", Underlying()),
            .storageUnavailable(.locked, "d3", "r3", Underlying()),
            .unknown("d4", "r4", Underlying()),
            .notConfigured("d5", "r5", Underlying())
        ]
        for (index, error) in cases.enumerated() {
            XCTAssertEqual(error.errorDescription, "d\(index + 1)")
            XCTAssertEqual(error.recoverySuggestion, "r\(index + 1)")
            XCTAssertTrue(error.underlyingError is Underlying)
        }
    }

    /// The family's initialiser contract: wrapping an error that is already this type must not
    /// flatten it into `.unknown`, or a consumer's `disposition` switch silently degrades.
    ///
    /// - Given: an existing `CredentialsError`
    /// - When: passed through `init(errorDescription:recoverySuggestion:error:)`
    /// - Then:
    ///    - the original case survives, and its disposition is unchanged
    func testInitPreservesAnExistingCredentialsError() {
        let original = CredentialsError.notSignedIn("signed out", "sign in")
        let rewrapped = CredentialsError(
            errorDescription: "ignored",
            recoverySuggestion: "ignored",
            error: original
        )
        XCTAssertEqual(rewrapped.disposition, .discard)
        XCTAssertEqual(rewrapped.errorDescription, "signed out")
    }

    /// - Given: a non-`CredentialsError` error
    /// - When: passed through the same initialiser
    /// - Then:
    ///    - it becomes `.unknown` and retains the underlying error
    func testInitWrapsAForeignError() {
        struct Foreign: Error {}
        let wrapped = CredentialsError(
            errorDescription: "d",
            recoverySuggestion: "r",
            error: Foreign()
        )
        XCTAssertEqual(wrapped.disposition, .retryWithBackoff)
        XCTAssertTrue(wrapped.underlyingError is Foreign)
    }
}
