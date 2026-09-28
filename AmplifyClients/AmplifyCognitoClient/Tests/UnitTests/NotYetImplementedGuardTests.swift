//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

/// The release guard for the not-yet-implemented stubs.
///
/// Every operation is implemented, and the `notYetImplemented` helper is gone; the scan stays, so no
/// stub can come back unlisted before the parity declaration.
///
/// `stillStubbed` lists every operation the client's sources still answer with `notYetImplemented`, and the
/// sources are scanned for them, so the list can neither hide a stub nor keep one that has gone. **Each W-row
/// removes its entries when it implements them.** When plugin parity is declared, `parityDeclared` becomes
/// `true`, and the build then fails while any entry remains: nothing ships that fails with "not implemented".
final class NotYetImplementedGuardTests: XCTestCase {

    /// Set to `true` with the parity declaration.
    static let parityDeclared = false

    /// Operation name → the row that implements it.
    static let stillStubbed: [String: String] = [:]

    /// `AmplifyClients/AmplifyCognitoClient/Sources`, from this file's path.
    private static let sources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources")

    /// Every `notYetImplemented("<operation>", row: "<row>")` call in the client's sources.
    private static func stubsInSources() throws -> [String: String] {
        let pattern = try NSRegularExpression(pattern: #"notYetImplemented\(\s*"([^"]+)",\s*row:\s*"([^"]+)"\s*\)"#)
        var found: [String: String] = [:]
        let files = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)
        while let file = files?.nextObject() as? URL {
            guard file.pathExtension == "swift" else {
                continue
            }
            let text = try String(contentsOf: file, encoding: .utf8)
            let range = NSRange(text.startIndex..., in: text)
            for match in pattern.matches(in: text, range: range) {
                guard let operation = Range(match.range(at: 1), in: text), let row = Range(match.range(at: 2), in: text) else {
                    continue
                }
                found[String(text[operation])] = String(text[row])
            }
        }
        return found
    }

    /// - Given: the client's sources
    /// - When: they are scanned for `notYetImplemented` calls
    /// - Then:
    ///    - the stubs found are exactly `stillStubbed`, each with its row
    func testTheStubListMatchesTheSources() throws {
        XCTAssertTrue(FileManager.default.fileExists(atPath: Self.sources.appendingPathComponent("AuthClientError.swift").path), "the scan's path is wrong")
        let found = try Self.stubsInSources()
        XCTAssertEqual(found, Self.stillStubbed, "a W-row that implements an operation removes it from stillStubbed")
    }

    /// - Given: the client's sources
    /// - When: they are scanned for the stub's helper and its message
    /// - Then:
    ///    - neither `func notYetImplemented` nor the text "not implemented yet" appears: every row has landed, so
    ///      a stub cannot come back through a helper or a hand-written message the call scan would miss
    func testNoStubHelperOrMessageRemains() throws {
        XCTAssertTrue(FileManager.default.fileExists(atPath: Self.sources.appendingPathComponent("AuthClientError.swift").path), "the scan's path is wrong")
        let helper = try NSRegularExpression(pattern: #"func\s+notYetImplemented\b"#)
        let message = try NSRegularExpression(pattern: "not implemented yet", options: .caseInsensitive)
        var hits: [String] = []
        let files = FileManager.default.enumerator(at: Self.sources, includingPropertiesForKeys: nil)
        while let file = files?.nextObject() as? URL {
            guard file.pathExtension == "swift" else {
                continue
            }
            let text = try String(contentsOf: file, encoding: .utf8)
            let range = NSRange(text.startIndex..., in: text)
            if helper.firstMatch(in: text, range: range) != nil || message.firstMatch(in: text, range: range) != nil {
                hits.append(file.lastPathComponent)
            }
        }
        XCTAssertEqual(hits, [], "a not-yet-implemented stub is back")
    }

    /// - Given: the parity declaration
    /// - When: it has been made
    /// - Then:
    ///    - no operation is still stubbed
    func testNothingIsStubbedOnceParityIsDeclared() {
        guard Self.parityDeclared else {
            return
        }
        XCTAssertEqual(Self.stillStubbed, [:], "parity is declared, but these still throw notYetImplemented")
    }
}
