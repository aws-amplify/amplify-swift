//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import InternalAmplifyKeychain
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `storageUnavailable`'s description quotes the keychain's own text as one sentence of one line.
final class StorageErrorTextTests: XCTestCase {

    /// - Given: a keychain failure whose text spans two lines and ends with a period, as the OS's text for a missing
    ///   entitlement does; the OS's own failures for a missing entitlement, a locked device and a denied
    ///   interaction; and a failure with no text of its own
    /// - When: each becomes `storageUnavailable` for "list the saved sessions"
    /// - Then:
    ///    - each description is one line that ends with exactly one period, with no ".." anywhere
    ///    - the two-line text reads as one sentence, its line break a space
    func testTheKeychainsTextIsOneSentenceOfOneLine() {
        let twoLines = KeychainAccessError.unknown(
            "Internal error when a required entitlement isn't present,\nclient has neither application-identifier nor keychain-access-groups entitlements."
        )
        let failures: [Error] = [
            twoLines,
            KeychainAccessError.securityError(errSecMissingEntitlement),
            KeychainAccessError.securityError(errSecInteractionNotAllowed),
            KeychainAccessError.securityError(errSecAuthFailed),
            FixtureError(description: "no keychain text")
        ]
        for failure in failures {
            let description = AuthClientError.storageUnavailable(from: failure, operation: "list the saved sessions").errorDescription
            XCTAssertTrue(description.hasPrefix("Secure storage could not list the saved sessions"), description)
            XCTAssertFalse(description.contains("\n"), description)
            XCTAssertFalse(description.contains(".."), description)
            XCTAssertTrue(description.hasSuffix("."), description)
        }
        XCTAssertEqual(
            AuthClientError.storageUnavailable(from: twoLines, operation: "list the saved sessions").errorDescription,
            "Secure storage could not list the saved sessions: Unexpected error occurred with message: Internal error when a "
                + "required entitlement isn't present, client has neither application-identifier nor keychain-access-groups entitlements."
        )
        XCTAssertEqual(
            AuthClientError.storageUnavailable(from: FixtureError(description: "x"), operation: "read the session").errorDescription,
            "Secure storage could not read the session."
        )
    }
}
