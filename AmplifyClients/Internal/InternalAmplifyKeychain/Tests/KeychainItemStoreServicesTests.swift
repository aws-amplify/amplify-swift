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

/// `KeychainItemStore.allServices(secItem:logger:)`: the services of every generic-password item the app can read, for
/// callers that cannot name them in advance.
final class KeychainItemStoreServicesTests: XCTestCase {

    private let logger = SilentLogger()

    /// - Given: nothing
    /// - When: the listing query is built
    /// - Then:
    ///    - it asks for every generic-password item's attributes in the data-protection keychain, and names no service,
    ///      account or access group, so it spans every service and group the app can read
    func testTheQueryListsEveryGenericPasswordItem() {
        let query = KeychainItemStore.listServicesQuery()

        XCTAssertEqual(query[KeychainConstants.Class] as? String, KeychainConstants.ClassGenericPassword)
        XCTAssertEqual(query[KeychainConstants.UseDataProtectionKeyChain] as? Bool, true)
        XCTAssertEqual(query[KeychainConstants.MatchLimit] as? String, KeychainConstants.MatchLimitAll as String)
        XCTAssertEqual(query[KeychainConstants.ReturnAttributes] as? Bool, true)
        XCTAssertNil(query[KeychainConstants.ReturnData])
        XCTAssertNil(query[KeychainConstants.AttributeService])
        XCTAssertNil(query[KeychainConstants.AttributeAccount])
        XCTAssertNil(query[KeychainConstants.AttributeAccessGroup])
    }

    /// - Given: a listing of several items, two in the same service and one with no service
    /// - When: it is interpreted, and a single-item listing too
    /// - Then:
    ///    - each service appears once, sorted, and the item with no service is dropped
    func testTheServicesAreDistinctAndSorted() throws {
        let items: [[String: Any]] = [
            [KeychainConstants.AttributeService: "b", KeychainConstants.AttributeAccount: "1"],
            [KeychainConstants.AttributeService: "a", KeychainConstants.AttributeAccount: "2"],
            [KeychainConstants.AttributeService: "b", KeychainConstants.AttributeAccount: "3"],
            [KeychainConstants.AttributeAccount: "4"]
        ]

        let many = try KeychainItemStore.services(fromStatus: errSecSuccess, result: items as NSArray, logger: logger)
        let one = try KeychainItemStore.services(fromStatus: errSecSuccess, result: items[1] as NSDictionary, logger: logger)

        XCTAssertEqual(many, ["a", "b"])
        XCTAssertEqual(one, ["a"])
    }

    /// - Given: an empty keychain, a failed listing and a result of the wrong type
    /// - When: each is interpreted
    /// - Then:
    ///    - the empty keychain lists none; the failure throws its status, and the wrong type throws: a failed listing is
    ///      never taken for an empty one
    func testAFailedListingThrows() {
        XCTAssertEqual(try KeychainItemStore.services(fromStatus: errSecItemNotFound, result: nil, logger: logger), [])
        XCTAssertThrowsError(
            try KeychainItemStore.services(fromStatus: errSecInteractionNotAllowed, result: nil, logger: logger)
        ) { error in
            XCTAssertEqual(error as? KeychainAccessError, .securityError(errSecInteractionNotAllowed))
        }
        XCTAssertThrowsError(try KeychainItemStore.services(fromStatus: errSecSuccess, result: "x" as NSString, logger: logger))
    }

    /// - Given: `SecItem` functions that record the query and answer with one item
    /// - When: the services are listed
    /// - Then:
    ///    - one `SecItemCopyMatching` runs, with the listing query, and its services are returned
    func testTheListingRunsTheQueryOnce() throws {
        let calls = QueryRecorder()
        let secItem = SecItemCalls(
            copyMatching: { query, result in
                calls.record(query as NSDictionary)
                result?.pointee = [
                    [KeychainConstants.AttributeService: "svc"]
                ] as NSArray
                return errSecSuccess
            },
            add: { _, _ in errSecUnimplemented },
            update: { _, _ in errSecUnimplemented },
            delete: { _ in errSecUnimplemented }
        )

        let services = try KeychainItemStore.allServices(secItem: secItem, logger: logger)

        XCTAssertEqual(services, ["svc"])
        XCTAssertEqual(calls.queries, [KeychainItemStore.listServicesQuery() as NSDictionary])
    }
}

/// The queries a fake `SecItemCopyMatching` was given.
private final class QueryRecorder: @unchecked Sendable {
    // `@unchecked Sendable`: `recorded` is only touched while holding `lock`.
    private let lock = NSLock()
    private var recorded: [NSDictionary] = []

    var queries: [NSDictionary] {
        lock.withLock { recorded }
    }

    func record(_ query: NSDictionary) {
        lock.withLock { recorded.append(query) }
    }
}
