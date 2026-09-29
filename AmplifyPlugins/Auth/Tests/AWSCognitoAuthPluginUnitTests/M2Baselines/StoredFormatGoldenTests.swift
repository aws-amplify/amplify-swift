//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

/// The stored-format gate: every stored value decodes to the same thing, and is written as the same JSON
/// tree.
///
/// The fixtures in `TestResources/GoldenStoredFormat/` were generated once, from the types as they were
/// before the engine extraction, and must never be regenerated. Byte equality is deliberately not
/// checked: `JSONEncoder`'s key order is not deterministic on Apple platforms.
@available(*, deprecated, message: "Exercises deprecated token and flow APIs, on purpose")
final class StoredFormatGoldenTests: XCTestCase {

    /// SHA-256 of `manifest.json`. Changing any fixture changes the manifest, which changes this value, so
    /// every fixture edit also has to edit this line, in review.
    static let pinnedManifestSHA256 = "a3a5b99da8b967aebc5895f0e71e62e827a0fb0f6813fa7e5e537ea890ecd8ba"

    static var directory: URL { GoldenFiles.directory("GoldenStoredFormat") }

    struct Manifest: Codable, Equatable {
        struct Entry: Codable, Equatable {
            let name: String
            let file: String
            let kind: StoredFormatFixture.Kind
            let type: String
            let summary: String
            let reencodesAs: String?
            let sha256: String
            /// The decoded value, field by field (`FieldDump`).
            let expectedFields: [String: String]
            /// The value the fixture was built from, field by field, where it differs from `expectedFields`.
            let constructedFields: [String: String]?
        }

        let note: String
        let encoder: String
        let fixtures: [Entry]
    }

    static func fixtureData(_ name: String) throws -> Data {
        try Data(contentsOf: directory.appendingPathComponent("\(name).json"))
    }

    static func loadManifest() throws -> Manifest {
        let data = try Data(contentsOf: directory.appendingPathComponent("manifest.json"))
        return try JSONDecoder().decode(Manifest.self, from: data)
    }

    static func manifestEntries() throws -> [String: Manifest.Entry] {
        try Dictionary(uniqueKeysWithValues: loadManifest().fixtures.map { ($0.name, $0) })
    }

    override func setUpWithError() throws {
        try XCTSkipIf(GoldenFiles.isGenerating, "Generating golden files")
    }

    // MARK: Integrity

    /// Test that the manifest is the one committed with the fixtures
    ///
    /// - Given: The committed `manifest.json`
    /// - When:
    ///    - Its SHA-256 is computed
    /// - Then:
    ///    - It equals the value pinned in this file
    ///
    func testManifestIsPinned() throws {
        let data = try Data(contentsOf: Self.directory.appendingPathComponent("manifest.json"))
        XCTAssertEqual(GoldenFiles.sha256Hex(data), Self.pinnedManifestSHA256)
    }

    /// Test that every fixture file is in the manifest with its hash, and every manifest entry is in code
    ///
    /// - Given: The fixture directory, the manifest and the fixture table in code
    /// - When:
    ///    - The three are compared
    /// - Then:
    ///    - They list the same fixtures, and every file's SHA-256 matches the manifest
    ///
    func testFixturesMatchManifest() throws {
        let manifest = try Self.loadManifest()
        let onDisk = try Set(
            FileManager.default.contentsOfDirectory(atPath: Self.directory.path)
                .filter { $0.hasSuffix(".json") && $0 != "manifest.json" }
        )
        XCTAssertEqual(Set(manifest.fixtures.map(\.file)), onDisk)
        for entry in manifest.fixtures {
            XCTAssertEqual(try GoldenFiles.sha256Hex(Self.fixtureData(entry.name)), entry.sha256, "\(entry.file) changed")
        }

        let inCode = Set(StoredFormatFixtures.all.map(\.name))
        let inManifest = Set(manifest.fixtures.map(\.name))
        XCTAssertEqual(inCode.subtracting(inManifest), [], "fixtures in code but not on disk")
        XCTAssertEqual(
            inManifest.subtracting(inCode).filter { !StoredFormatFixtures.isPlatformDependent($0) },
            [],
            "fixtures on disk but not in code"
        )
    }

    // MARK: (a) + (b) Throwing decode, compared field by field

    /// Test that every fixture decodes, and decodes to the recorded fields
    ///
    /// - Given: Every fixture: canonical, permuted and legacy
    /// - When:
    ///    - It is decoded with `JSONDecoder()`, with no `try?` anywhere in the path
    /// - Then:
    ///    - Decoding does not throw
    ///    - The decoded value's fields equal the manifest's expected fields, and those the code expects
    ///
    func testEveryFixtureDecodesToTheRecordedFields() throws {
        let entries = try Self.manifestEntries()
        for fixture in StoredFormatFixtures.all {
            let entry = try XCTUnwrap(entries[fixture.name], fixture.name)
            let decoded: [String: String]
            do {
                decoded = try fixture.decodedFields(Self.fixtureData(fixture.name))
            } catch {
                XCTFail("\(fixture.name) no longer decodes: \(error)")
                continue
            }
            assertFields(decoded, entry.expectedFields, "\(fixture.name) vs manifest")
            assertFields(decoded, fixture.expectedFields(), "\(fixture.name) vs code")
        }
    }

    /// Test that every must-throw fixture is still rejected, for the same reason
    ///
    /// - Given: The rejected fixtures: inputs today's decoders refuse
    /// - When:
    ///    - Each is decoded with `JSONDecoder()`
    /// - Then:
    ///    - Decoding throws the recorded `DecodingError` case. A decoder that became lenient fails here
    ///
    func testRejectedFixturesStillThrow() throws {
        let rejected = StoredFormatFixtures.all.filter { $0.kind == .rejected }
        XCTAssertGreaterThanOrEqual(rejected.count, 12)
        for fixture in rejected {
            let result = try fixture.decodedFields(Self.fixtureData(fixture.name))
            XCTAssertEqual(result, fixture.expectedFields(), "\(fixture.name) no longer fails to decode as recorded")
        }
    }

    // MARK: (c) Re-encode compared as a JSON tree

    /// Test that re-encoding every fixture gives its canonical JSON tree
    ///
    /// - Given: Every fixture
    /// - When:
    ///    - It is decoded and re-encoded with `JSONEncoder()`, as the credential store does
    ///    - Both that output and the canonical fixture are parsed with `JSONSerialization`
    /// - Then:
    ///    - The trees are equal, with `null` distinct from an absent key. A permuted or legacy fixture is
    ///      compared with its canonical sibling
    ///
    func testReencodingGivesTheCanonicalTree() throws {
        for fixture in StoredFormatFixtures.all where fixture.kind != .rejected {
            let reencoded = try fixture.decodeAndReencode(Self.fixtureData(fixture.name))
            let canonical = try Self.fixtureData(fixture.reencodesAs ?? fixture.name)
            XCTAssertTrue(
                try CanonicalJSON.areEqual(reencoded, canonical),
                "\(fixture.name): re-encoded\n\(CanonicalJSON.string(reencoded))\nexpected\n\(CanonicalJSON.string(canonical))"
            )
        }
    }

    // MARK: (d) Construction check

    /// Test that every value built in code encodes to its canonical fixture's tree
    ///
    /// - Given: Each canonical fixture's value, built from the literals in `StoredFormatFixtures`
    /// - When:
    ///    - It is encoded with `JSONEncoder()`
    /// - Then:
    ///    - The result is tree-equal to the fixture, and the value's fields are the recorded construction
    ///
    func testValuesBuiltInCodeEncodeToTheirFixtures() throws {
        let entries = try Self.manifestEntries()
        for fixture in StoredFormatFixtures.all where fixture.kind == .canonical {
            let encode = try XCTUnwrap(fixture.encodeBuiltValue, fixture.name)
            let constructed = try XCTUnwrap(fixture.constructedFields, fixture.name)()
            let entry = try XCTUnwrap(entries[fixture.name], fixture.name)
            let encoded = try encode()
            let golden = try Self.fixtureData(fixture.name)
            XCTAssertTrue(
                try CanonicalJSON.areEqual(encoded, golden),
                "\(fixture.name): encoded\n\(CanonicalJSON.string(encoded))\nfixture\n\(CanonicalJSON.string(golden))"
            )
            assertFields(constructed, entry.constructedFields ?? entry.expectedFields, "\(fixture.name) construction")
        }
    }

    // MARK: Hook for the forks

    /// A fork's view of the stored format: `check` decodes a fixture with the fork type, converts to the
    /// public type (and back), and throws or fails if anything differs.
    struct ForkCrossDecoder {
        /// Fixtures whose base name (without `permuted-` / `legacy-`) starts with this prefix are checked,
        /// for example `"authFlowType-"`.
        let fixturePrefix: String
        let check: (_ fixture: Data) throws -> Void
    }

    /// The engine forks `EngineUserPoolTokens`, `EngineAWSCredentials`, `EngineAuthFlowType` and
    /// `EngineAuthProvider` are registered here, so every committed fixture (legacy and permuted included) is
    /// also decoded by the fork, in both directions.
    ///
    /// Tokens, credentials, `SignedInData` and `AmplifyCredentials`: `StoredFormatForkCrossDecoders`.
    /// Flow type, factor type and provider: `StoredFormatForkCrossDecoders+S5b.swift`.
    static var forkCrossDecoders: [ForkCrossDecoder] { StoredFormatForkCrossDecoders.all + flowTypeForkCrossDecoders }

    /// Test that every registered fork decodes the committed fixtures as the public type does
    ///
    /// - Given: The fork cross-decoders registered in `forkCrossDecoders`
    /// - When:
    ///    - Each is run on every committed fixture that matches its prefix
    /// - Then:
    ///    - None throws, and each matches at least one fixture
    ///    - Where `AuthFactorType.webAuthn` does not exist (tvOS, watchOS), the fixtures that hold it
    ///      (`StoredFormatFixtures.isPlatformDependent(_:)`) are rejected instead, as the plugin rejects them there
    ///
    func testForkCrossDecoding() throws {
        let names = try Self.loadManifest().fixtures.map(\.name)
        for decoder in Self.forkCrossDecoders {
            let matching = names.filter { name in
                ["", "permuted-", "legacy-"].contains { name.hasPrefix($0 + decoder.fixturePrefix) }
            }
            XCTAssertFalse(matching.isEmpty, "no fixture matches \(decoder.fixturePrefix)")
            for name in matching {
                let fixture = try Self.fixtureData(name)
                if StoredFormatFixtures.isPlatformDependent(name), !StoredFormatFixtures.hasPlatformDependentTypes {
                    XCTAssertThrowsError(try decoder.check(fixture), "\(name) decodes without AuthFactorType.webAuthn") { error in
                        XCTAssertTrue(error is DecodingError, "\(name): \(error)")
                    }
                } else {
                    XCTAssertNoThrow(try decoder.check(fixture), name)
                }
            }
        }
    }
}

/// Compares two field dumps and reports each differing path on its own line.
func assertFields(
    _ actual: [String: String],
    _ expected: [String: String],
    _ context: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard actual != expected else { return }
    let paths = Set(actual.keys).union(expected.keys).sorted()
    let differences = paths.compactMap { path -> String? in
        actual[path] == expected[path] ? nil
            : "  \(path): expected \(expected[path] ?? "<absent>"), got \(actual[path] ?? "<absent>")"
    }
    XCTFail("\(context):\n\(differences.joined(separator: "\n"))", file: file, line: line)
}

/// Writes the canonical and permuted fixtures and the manifest. Runs only with `AMPLIFY_GENERATE_GOLDEN=1`.
///
/// ```
/// AMPLIFY_GENERATE_GOLDEN=1 swift test --filter StoredFormatFixtureGenerator
/// ```
///
/// Used once, when the baselines were captured. After that the fixtures are frozen, and the generator
/// refuses to overwrite them unless `AMPLIFY_GOLDEN_OVERWRITE_FROZEN=1` is also set. Legacy fixtures are
/// hand-written, and the generator only records them in the manifest.
///
/// `AMPLIFY_GOLDEN_RAW_DIR=<dir>` writes each canonical value's raw `JSONEncoder()` bytes (not key-sorted)
/// to `<dir>` and nothing else, which is how the key-order instability was measured on the real types.
@available(*, deprecated, message: "Exercises deprecated token and flow APIs, on purpose")
final class StoredFormatFixtureGenerator: XCTestCase {

    func testGenerateStoredFormatFixtures() throws {
        let environment = ProcessInfo.processInfo.environment
        let rawDirectory = environment["AMPLIFY_GOLDEN_RAW_DIR"].map { URL(fileURLWithPath: $0, isDirectory: true) }
        try XCTSkipUnless(GoldenFiles.isGenerating || rawDirectory != nil, "Set AMPLIFY_GENERATE_GOLDEN=1 to generate")

        let fixtures = StoredFormatFixtures.all
        if let rawDirectory {
            for fixture in fixtures where fixture.kind == .canonical {
                let raw = try XCTUnwrap(fixture.encodeBuiltValue)()
                try GoldenFiles.write(raw, to: rawDirectory.appendingPathComponent(fixture.fileName))
            }
            return
        }

        let directory = StoredFormatGoldenTests.directory
        let manifestURL = directory.appendingPathComponent("manifest.json")
        if FileManager.default.fileExists(atPath: manifestURL.path),
           environment["AMPLIFY_GOLDEN_OVERWRITE_FROZEN"] != "1" {
            XCTFail("The stored-format fixtures are frozen since S0b. Regenerating them defeats gate G2.")
            return
        }

        func line(_ data: Data) -> Data { data + Data("\n".utf8) }
        let canonicalByName = Dictionary(uniqueKeysWithValues: fixtures.map { ($0.name, $0) })
        var entries: [StoredFormatGoldenTests.Manifest.Entry] = []
        for fixture in fixtures {
            let url = directory.appendingPathComponent(fixture.fileName)
            switch fixture.kind {
            case .canonical:
                let raw = try XCTUnwrap(fixture.encodeBuiltValue)()
                try GoldenFiles.write(line(CanonicalJSON.canonicalize(raw)), to: url)
            case .permuted:
                let sibling = try XCTUnwrap(canonicalByName[XCTUnwrap(fixture.reencodesAs)])
                let raw = try XCTUnwrap(sibling.encodeBuiltValue)()
                try GoldenFiles.write(line(CanonicalJSON.reverseSortedText(raw)), to: url)
            case .legacy, .rejected:
                break
            }
            let data = try Data(contentsOf: url)
            let expected = fixture.expectedFields()
            let constructed = fixture.constructedFields?()
            entries.append(.init(
                name: fixture.name,
                file: fixture.fileName,
                kind: fixture.kind,
                type: fixture.type,
                summary: fixture.summary,
                reencodesAs: fixture.reencodesAs,
                sha256: GoldenFiles.sha256Hex(data),
                expectedFields: expected,
                constructedFields: constructed == expected ? nil : constructed
            ))
        }

        let manifest = StoredFormatGoldenTests.Manifest(
            note: "Generated once at M2 step S0b from the pre-M2 types. Never regenerate. Compared as decoded fields and JSON trees, not bytes.",
            encoder: "JSONEncoder() / JSONDecoder() with default strategies (dates as seconds since 2001-01-01)",
            fixtures: entries.sorted { $0.name < $1.name }
        )
        let manifestData = try GoldenFiles.snapshotData(manifest)
        try GoldenFiles.write(manifestData, to: manifestURL)
        print("GoldenStoredFormat manifest SHA-256: \(GoldenFiles.sha256Hex(manifestData))")
    }
}
