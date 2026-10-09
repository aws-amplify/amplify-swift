//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import Security
import XCTest
@testable import InternalAmplifyKeychain

/// `KeychainItemStore` hands every `SecItem` status to a static interpreter, so the mapping from status
/// and result to value or error is tested here without the real keychain.
final class KeychainItemStoreInterpretationTests: XCTestCase {

    private let logger = SilentLogger()

    // MARK: Data reads

    /// A successful read returns the item's bytes.
    ///
    /// - Given: `errSecSuccess` with a `Data` result
    /// - When: the read is interpreted
    /// - Then:
    ///    - the data is returned
    func testDataReadSuccess() throws {
        let value = Data("value".utf8)
        let data = try KeychainItemStore.data(fromStatus: errSecSuccess, result: value as NSData, key: "key", logger: logger)
        XCTAssertEqual(data, value)
    }

    /// An absent item is reported as `itemNotFound`, which is distinct from every other failure.
    ///
    /// - Given: `errSecItemNotFound`
    /// - When: the read is interpreted
    /// - Then:
    ///    - `KeychainAccessError.itemNotFound` is thrown
    func testDataReadNotFound() {
        XCTAssertThrowsError(
            try KeychainItemStore.data(fromStatus: errSecItemNotFound, result: nil, key: "key", logger: logger)
        ) { error in
            XCTAssertEqual(error as? KeychainAccessError, .itemNotFound)
        }
    }

    /// Any other status is carried through unchanged.
    ///
    /// - Given: `errSecInteractionNotAllowed`
    /// - When: the read is interpreted
    /// - Then:
    ///    - `securityError` with that exact status is thrown
    func testDataReadFailureCarriesStatus() {
        XCTAssertThrowsError(
            try KeychainItemStore.data(fromStatus: errSecInteractionNotAllowed, result: nil, key: "key", logger: logger)
        ) { error in
            XCTAssertEqual(error as? KeychainAccessError, .securityError(errSecInteractionNotAllowed))
        }
    }

    /// A success that returned something other than data is an unexpected result, as it always was.
    ///
    /// - Given: `errSecSuccess` with a non-`Data` result
    /// - When: the read is interpreted
    /// - Then:
    ///    - `unknown` with the long-standing message is thrown
    func testDataReadWrongType() {
        XCTAssertThrowsError(
            try KeychainItemStore.data(fromStatus: errSecSuccess, result: "text" as NSString, key: "key", logger: logger)
        ) { error in
            XCTAssertEqual(error as? KeychainAccessError, .unknown("The keychain item retrieved is not the correct type"))
        }
    }

    // MARK: Listing

    /// A listing returns every item's account name.
    ///
    /// - Given: `errSecSuccess` with an array of attribute dictionaries, one of them without an account
    /// - When: the listing is interpreted
    /// - Then:
    ///    - the account names are returned in order and the item without one is skipped
    func testListingSuccess() throws {
        let result: NSArray = [
            [kSecAttrAccount as String: "first", kSecAttrService as String: "service"] as NSDictionary,
            [kSecAttrService as String: "service"] as NSDictionary,
            [kSecAttrAccount as String: "second"] as NSDictionary
        ]
        let accounts = try KeychainItemStore.accounts(fromStatus: errSecSuccess, result: result, logger: logger)
        XCTAssertEqual(accounts, ["first", "second"])
    }

    /// A single dictionary, rather than an array of one, is still read.
    ///
    /// - Given: `errSecSuccess` with a single attribute dictionary
    /// - When: the listing is interpreted
    /// - Then:
    ///    - its account name is returned
    func testListingSingleDictionary() throws {
        let result: NSDictionary = [kSecAttrAccount as String: "only"]
        let accounts = try KeychainItemStore.accounts(fromStatus: errSecSuccess, result: result, logger: logger)
        XCTAssertEqual(accounts, ["only"])
    }

    /// Entries keep each row's access group, so an account in two groups is two distinct entries.
    ///
    /// - Given: rows for one account in two groups, a row without a group, and a row without an account
    /// - When: the listing is interpreted as entries, and as accounts
    /// - Then:
    ///    - each row with an account becomes one entry, with its group or `nil`
    ///    - the row without an account is dropped
    ///    - the account listing is the same rows' accounts, in the same order
    func testListingEntriesCarryAccessGroups() throws {
        let result: NSArray = [
            [kSecAttrAccount as String: "authConfiguration", kSecAttrAccessGroup as String: "TEAM.default"],
            [kSecAttrAccount as String: "authConfiguration", kSecAttrAccessGroup as String: "TEAM.shared"],
            [kSecAttrAccount as String: "ungrouped"],
            [kSecAttrAccessGroup as String: "TEAM.default"]
        ]

        let entries = try KeychainItemStore.entries(fromStatus: errSecSuccess, result: result, logger: logger)
        XCTAssertEqual(entries, [
            KeychainEntry(account: "authConfiguration", accessGroup: "TEAM.default"),
            KeychainEntry(account: "authConfiguration", accessGroup: "TEAM.shared"),
            KeychainEntry(account: "ungrouped", accessGroup: nil)
        ])
        XCTAssertEqual(
            try KeychainItemStore.accounts(fromStatus: errSecSuccess, result: result, logger: logger),
            ["authConfiguration", "authConfiguration", "ungrouped"]
        )
    }

    /// An empty service is a valid answer for enumeration.
    ///
    /// - Given: `errSecItemNotFound`
    /// - When: the listing is interpreted
    /// - Then:
    ///    - an empty list is returned, not an error
    func testListingEmptyServiceIsEmpty() throws {
        let accounts = try KeychainItemStore.accounts(fromStatus: errSecItemNotFound, result: nil, logger: logger)
        XCTAssertEqual(accounts, [])
    }

    /// A locked device must throw. Returning `[]` would tell an account picker there are no sessions
    /// while sessions exist.
    ///
    /// - Given: `errSecInteractionNotAllowed`
    /// - When: the listing is interpreted
    /// - Then:
    ///    - `securityError` is thrown, and its reason classifies as `.locked`
    func testListingLockedThrowsNeverEmpty() {
        XCTAssertThrowsError(
            try KeychainItemStore.accounts(fromStatus: errSecInteractionNotAllowed, result: nil, logger: logger)
        ) { error in
            let accessError = error as? KeychainAccessError
            XCTAssertEqual(accessError, .securityError(errSecInteractionNotAllowed))
            XCTAssertEqual(accessError?.storageUnavailableReason, .locked)
        }
    }

    /// A success with an unreadable result is an error, not an empty listing.
    ///
    /// - Given: `errSecSuccess` with a result that is neither an array nor a dictionary
    /// - When: the listing is interpreted
    /// - Then:
    ///    - `unknown` is thrown
    func testListingWrongTypeThrows() {
        XCTAssertThrowsError(
            try KeychainItemStore.accounts(fromStatus: errSecSuccess, result: "text" as NSString, logger: logger)
        ) { error in
            guard case .unknown = error as? KeychainAccessError else {
                return XCTFail("Expected unknown, got \(error)")
            }
        }
    }

    // MARK: Conditional writes

    /// A conditional write reports success as `true`, its precondition failing as `false`, and throws
    /// for anything else.
    ///
    /// - Given: success, the refusal status, and an unrelated failure
    /// - When: each outcome is interpreted
    /// - Then:
    ///    - they map to `true`, `false` and a thrown `securityError` respectively
    func testConditionalWriteOutcome() throws {
        XCTAssertTrue(try KeychainItemStore.writeOutcome(
            fromStatus: errSecSuccess, refusedBy: errSecDuplicateItem, key: "key", logger: logger
        ))
        XCTAssertFalse(try KeychainItemStore.writeOutcome(
            fromStatus: errSecDuplicateItem, refusedBy: errSecDuplicateItem, key: "key", logger: logger
        ))
        XCTAssertFalse(try KeychainItemStore.writeOutcome(
            fromStatus: errSecItemNotFound, refusedBy: errSecItemNotFound, key: "key", logger: logger
        ))
        XCTAssertThrowsError(try KeychainItemStore.writeOutcome(
            fromStatus: errSecInteractionNotAllowed, refusedBy: errSecDuplicateItem, key: "key", logger: logger
        )) { error in
            XCTAssertEqual(error as? KeychainAccessError, .securityError(errSecInteractionNotAllowed))
        }
    }

    /// The error lines of a failed read and a failed conditional write name the record's kind, never its key:
    /// a device key holds the username.
    ///
    /// - Given: a device-metadata key holding a username, and a key without a `.`
    /// - When: a read and a conditional write fail with an unexpected status for each
    /// - Then:
    ///    - each error line names the status and the kind (`deviceMetadata`, or `unknown`), and holds no part
    ///      of the key before its kind
    func testErrorLinesNameTheKindNotTheKey() {
        for (key, kind) in [("amplify.pool.user.name@example.com.deviceMetadata", "deviceMetadata"), ("user-name", "unknown")] {
            let recording = RecordingLogger()
            XCTAssertThrowsError(
                try KeychainItemStore.data(fromStatus: errSecInteractionNotAllowed, result: nil, key: key, logger: recording)
            )
            XCTAssertThrowsError(try KeychainItemStore.writeOutcome(
                fromStatus: errSecInteractionNotAllowed, refusedBy: errSecDuplicateItem, key: key, logger: recording
            ))
            let lines = recording.messages(at: .error)
            XCTAssertEqual(lines, [
                "[KeychainStore] Error of status=\(errSecInteractionNotAllowed) occurred when attempting to retrieve a Keychain item of kind=\(kind)",
                "[KeychainStore] Error during conditional write with status=\(errSecInteractionNotAllowed) for kind=\(kind)"
            ])
            for line in lines {
                XCTAssertFalse(line.contains("user"), line)
            }
        }
    }

    /// A move reports what happened, and throws for anything unexpected.
    ///
    /// - Given: success, not-found, duplicate, and an unrelated failure
    /// - When: each outcome is interpreted
    /// - Then:
    ///    - they map to `.moved`, `.notFound`, `.destinationOccupied` and a thrown `securityError`
    func testMoveOutcome() throws {
        XCTAssertEqual(try KeychainItemStore.moveOutcome(fromStatus: errSecSuccess, logger: logger), .moved)
        XCTAssertEqual(try KeychainItemStore.moveOutcome(fromStatus: errSecItemNotFound, logger: logger), .notFound)
        XCTAssertEqual(
            try KeychainItemStore.moveOutcome(fromStatus: errSecDuplicateItem, logger: logger),
            .destinationOccupied
        )
        XCTAssertThrowsError(try KeychainItemStore.moveOutcome(
            fromStatus: errSecInteractionNotAllowed, logger: logger
        )) { error in
            XCTAssertEqual(error as? KeychainAccessError, .securityError(errSecInteractionNotAllowed))
        }
    }

    // MARK: Errors

    /// A security error describes itself with the same text the plugin has always used.
    ///
    /// - Given: a missing-entitlement security error and an `itemNotFound`
    /// - When: their descriptions are read
    /// - Then:
    ///    - they match `KeychainStatus` and the long-standing not-found message
    func testErrorDescriptions() {
        XCTAssertEqual(
            KeychainAccessError.securityError(errSecMissingEntitlement).errorDescription,
            KeychainStatus.missingEntitlement.description
        )
        XCTAssertEqual(KeychainAccessError.itemNotFound.errorDescription, "Unable to find the keychain item")
        XCTAssertEqual(KeychainStatus(status: errSecDuplicateItem), .duplicateItem)
        XCTAssertEqual(KeychainStatus(status: errSecItemNotFound), .itemNotFound)
    }
}
