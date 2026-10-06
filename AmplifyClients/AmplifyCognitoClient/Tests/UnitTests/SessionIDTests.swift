//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

final class SessionIDTests: XCTestCase {

    /// - Given: identifiers built only from the permitted charset, at both length bounds
    /// - When: passed to `named(_:)`
    /// - Then:
    ///    - each is accepted and round-trips through `stringValue`
    func testAcceptsPermittedIdentifiers() throws {
        let longest = String(repeating: "a", count: SessionID.maximumLength)
        for id in ["work", "Work-2", "tenant_42", "a", "A-z_0-9", longest] {
            XCTAssertEqual(try SessionID.named(id).stringValue, id)
        }
    }

    /// - Given: an empty string
    /// - When: passed to `named(_:)`
    /// - Then:
    ///    - it throws `invalidSessionID`
    func testRejectsEmpty() {
        XCTAssertThrowsError(try SessionID.named("")) { error in
            guard case AuthClientError.invalidSessionID = error else {
                return XCTFail("Expected invalidSessionID, got \(error)")
            }
        }
    }

    /// - Given: an identifier one character over the limit
    /// - When: passed to `named(_:)`
    /// - Then:
    ///    - it throws `invalidSessionID`
    func testRejectsOverlong() {
        let tooLong = String(repeating: "a", count: SessionID.maximumLength + 1)
        XCTAssertThrowsError(try SessionID.named(tooLong))
    }

    /// The charset rule is what keeps the storage key unambiguous, so the delimiter characters in
    /// particular must never get through.
    ///
    /// - Given: identifiers containing `.`, `/`, `$`, a space, and a non-ASCII letter
    /// - When: passed to `named(_:)`
    /// - Then:
    ///    - each throws, and the message names the offending character but never repeats the ID
    func testRejectsForbiddenCharactersAndNamesThem() {
        let cases: [(String, String)] = [
            ("a.b", "."), ("a/b", "/"), ("$work", "$"), ("my work", " "), ("café", "é")
        ]
        for (id, offender) in cases {
            XCTAssertThrowsError(try SessionID.named(id), id) { error in
                guard case AuthClientError.invalidSessionID(let description, let suggestion, _) = error else {
                    return XCTFail("Expected invalidSessionID for \(id), got \(error)")
                }
                XCTAssertTrue(description.contains("\"\(offender)\""), "Message should name \(offender): \(description)")
                XCTAssertFalse(description.contains(id), "Message repeats the ID: \(description)")
                XCTAssertFalse(suggestion.contains(id), "Suggestion repeats the ID: \(suggestion)")
            }
        }
    }

    /// The reason for the `$`: an app naming a session "default" for its own purposes must not land
    /// on the record that adopts the migrated plugin credentials.
    ///
    /// - Given: `named("default")`, and other spellings near the sentinel
    /// - When: compared with the library's sentinel
    /// - Then:
    ///    - none equals `.default`: only the sentinel's own `stringValue` reads back as `.default`
    func testSentinelIsUnforgeable() throws {
        XCTAssertNotEqual(try SessionID.named("default"), .default)
        for spelling in ["$Default", "$default ", " $default", "$$default", "$defaults"] {
            XCTAssertThrowsError(try SessionID.named(spelling), spelling)
        }
    }

    /// A persisted `stringValue` always rebuilds its ID, `.default`'s included.
    ///
    /// - Given: `.default`'s `stringValue`, `"$default"`, and a named ID's `stringValue`
    /// - When: each is passed to `named(_:)`
    /// - Then:
    ///    - `"$default"` is `.default`, and the named ID is itself
    func testNamedRebuildsAPersistedStringValue() throws {
        XCTAssertEqual(try SessionID.named(SessionID.default.stringValue), .default)
        XCTAssertEqual(try SessionID.named("$default"), .default)
        let work = try SessionID.named("work")
        XCTAssertEqual(try SessionID.named(work.stringValue), work)
    }

    /// `.default` is the only sentinel: the adopted plugin session lives under it, so no second ID
    /// can address the plugin's record.
    ///
    /// - Given: the retired `$plugin` spelling, as a stored key segment and as encoded JSON
    /// - When: it is read back
    /// - Then:
    ///    - it is rejected in both forms
    func testRetiredPluginSentinelIsNotASessionID() {
        XCTAssertNil(SessionID(storageComponent: "$plugin"))
        XCTAssertThrowsError(try JSONDecoder().decode(SessionID.self, from: Data(#""$plugin""#.utf8)))
        XCTAssertThrowsError(try SessionID.named("$plugin"))
    }

    /// Merging IDs that differ only by case would silently cross two users' credentials.
    ///
    /// - Given: `"Work"` and `"work"`
    /// - When: compared
    /// - Then:
    ///    - they are different sessions
    func testIsCaseSensitive() throws {
        XCTAssertNotEqual(try SessionID.named("Work"), try SessionID.named("work"))
    }

    /// - Given: two library-minted IDs
    /// - When: inspected
    /// - Then:
    ///    - both are distinct and both would pass `named(_:)`, so a minted ID is always storable
    func testNewIsUniqueAndValid() throws {
        let first = SessionID.new()
        let second = SessionID.new()
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(try SessionID.named(first.stringValue), first)
    }

    /// - Given: a named ID, a minted ID and the sentinel
    /// - When: encoded and decoded
    /// - Then:
    ///    - each round-trips to an equal value, the sentinel included
    func testCodableRoundTrip() throws {
        for id in [try SessionID.named("work"), .default, .new()] {
            let data = try JSONEncoder().encode(id)
            XCTAssertEqual(try JSONDecoder().decode(SessionID.self, from: data), id)
        }
    }

    /// Decoding is the one path that bypasses `named(_:)`, so it must apply the same rule.
    ///
    /// - Given: a JSON string containing a forbidden character
    /// - When: decoded as a `SessionID`
    /// - Then:
    ///    - decoding throws rather than producing an ID that could corrupt a storage key
    func testDecodingRejectsInvalidValue() {
        XCTAssertThrowsError(try JSONDecoder().decode(SessionID.self, from: Data(#""user@example.com""#.utf8))) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                return XCTFail("Expected dataCorrupted, got \(error)")
            }
            XCTAssertFalse(context.debugDescription.contains("user@example.com"), context.debugDescription)
        }
        let data = Data("\"a.b\"".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(SessionID.self, from: data))
    }
}
