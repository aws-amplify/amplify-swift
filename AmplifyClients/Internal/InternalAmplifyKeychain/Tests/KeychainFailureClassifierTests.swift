//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import InternalAmplifyKeychain

final class KeychainFailureClassifierTests: XCTestCase {

    /// A locked device is the most common keychain failure at background launch, and it resolves
    /// on unlock, so it must never read as "signed out".
    ///
    /// - Given: `errSecInteractionNotAllowed`
    /// - When: it is classified
    /// - Then:
    ///    - the reason is `.locked`
    func testInteractionNotAllowedIsLocked() {
        XCTAssertEqual(StorageUnavailableReason(keychainStatus: errSecInteractionNotAllowed), .locked)
    }

    /// Entitlement and access failures need a build or provisioning fix, not a retry.
    ///
    /// - Given: `errSecMissingEntitlement`, `errSecAuthFailed` and `errSecNoAccessForItem`
    /// - When: each is classified
    /// - Then:
    ///    - every one is `.denied`
    func testEntitlementAndAccessFailuresAreDenied() {
        XCTAssertEqual(StorageUnavailableReason(keychainStatus: errSecMissingEntitlement), .denied)
        XCTAssertEqual(StorageUnavailableReason(keychainStatus: errSecAuthFailed), .denied)
        XCTAssertEqual(StorageUnavailableReason(keychainStatus: errSecNoAccessForItem), .denied)
    }

    /// I/O and keystore-unavailable failures are transient.
    ///
    /// - Given: `errSecIO` and `errSecNotAvailable`
    /// - When: each is classified
    /// - Then:
    ///    - both are `.interrupted`
    func testTransientFailuresAreInterrupted() {
        XCTAssertEqual(StorageUnavailableReason(keychainStatus: errSecIO), .interrupted)
        XCTAssertEqual(StorageUnavailableReason(keychainStatus: errSecNotAvailable), .interrupted)
    }

    /// Statuses that do not mean "unavailable" must not be classified as if they did. In particular,
    /// an absent item is an answer, not an outage.
    ///
    /// - Given: success, item-not-found, duplicate-item, a parameter error, and an arbitrary status
    /// - When: each is classified
    /// - Then:
    ///    - every one is `nil`
    func testUnmappedStatusesAreNil() {
        XCTAssertNil(StorageUnavailableReason(keychainStatus: errSecSuccess))
        XCTAssertNil(StorageUnavailableReason(keychainStatus: errSecItemNotFound))
        XCTAssertNil(StorageUnavailableReason(keychainStatus: errSecDuplicateItem))
        XCTAssertNil(StorageUnavailableReason(keychainStatus: errSecParam))
        XCTAssertNil(StorageUnavailableReason(keychainStatus: -1))
    }

    /// The error type exposes the same classification, and only for security errors.
    ///
    /// - Given: a locked security error, an unmapped security error, `itemNotFound`, and `unknown`
    /// - When: `storageUnavailableReason` is read
    /// - Then:
    ///    - it is `.locked` for the locked status and `nil` for every other case
    func testAccessErrorExposesClassification() {
        XCTAssertEqual(KeychainAccessError.securityError(errSecInteractionNotAllowed).storageUnavailableReason, .locked)
        XCTAssertNil(KeychainAccessError.securityError(errSecParam).storageUnavailableReason)
        XCTAssertNil(KeychainAccessError.itemNotFound.storageUnavailableReason)
        XCTAssertNil(KeychainAccessError.unknown("unexpected").storageUnavailableReason)
    }
}
