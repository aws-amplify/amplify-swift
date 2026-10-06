//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin

/// `FieldDump` records a stored property under its encoded key (`FieldDump.encodedKeyAliases`). These tests
/// check that each alias is exactly the type's encoded key, and that the stored-format gate still catches a
/// changed key or value.
final class FieldDumpEncodedKeyTests: XCTestCase {

    static var storedFormat: URL { GoldenFiles.directory("GoldenStoredFormat") }

    static func tokensFixture() throws -> Data {
        try Data(contentsOf: storedFormat.appendingPathComponent("userPoolTokens.json"))
    }

    /// The `userPoolTokens` fixture's fields as the locked manifest records them.
    static func manifestFields() throws -> [String: String] {
        let data = try Data(contentsOf: storedFormat.appendingPathComponent("manifest.json"))
        let manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let fixtures = try XCTUnwrap(manifest["fixtures"] as? [[String: Any]])
        let entry = try XCTUnwrap(fixtures.first { $0["name"] as? String == "userPoolTokens" })
        return try XCTUnwrap(entry["expectedFields"] as? [String: String])
    }

    static func dump(_ data: Data) throws -> [String: String] {
        try FieldDump.fields(of: JSONDecoder().decode(AWSCognitoUserPoolTokens.self, from: data))
    }

    /// The fixture's JSON object, edited by `edit`, written back.
    static func editedFixture(_ edit: (inout [String: Any]) throws -> Void) throws -> Data {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: tokensFixture()) as? [String: Any])
        try edit(&object)
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    /// Test that every alias names the type's encoded key, and nothing else is renamed
    ///
    /// - Given: The alias table, whose only type is `AWSCognitoUserPoolTokens`, and its `userPoolTokens` fixture
    /// - When:
    ///    - The fixture is decoded and encoded again with `JSONEncoder()`, and the value is reflected
    /// - Then:
    ///    - The value stores `legacyExpiration`, which the JSON does not hold, and the JSON holds `expiration`
    ///    - The JSON's keys are exactly the stored properties' recorded names
    ///    - The JSON's `expiration` is the value the dump records under `$.expiration`
    ///
    func testEveryAliasIsTheTypesEncodedKey() throws {
        XCTAssertEqual(
            FieldDump.encodedKeyAliases.keys.map { $0 },
            [ObjectIdentifier(AWSCognitoUserPoolTokens.self)],
            "a new alias needs its own check here"
        )
        XCTAssertEqual(FieldDump.encodedKeyAliases[ObjectIdentifier(AWSCognitoUserPoolTokens.self)], ["legacyExpiration": "expiration"])

        let tokens = try JSONDecoder().decode(AWSCognitoUserPoolTokens.self, from: Self.tokensFixture())
        let labels = Mirror(reflecting: tokens).children.compactMap(\.label)
        XCTAssertTrue(labels.contains("legacyExpiration"), "\(labels)")
        let encoded = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(tokens)) as? [String: Any])
        XCTAssertNil(encoded["legacyExpiration"])
        XCTAssertEqual(
            Set(encoded.keys),
            Set(labels.map { FieldDump.recordedName(of: $0, in: AWSCognitoUserPoolTokens.self) })
        )

        let seconds = try XCTUnwrap(encoded["expiration"] as? Double)
        XCTAssertEqual(FieldDump.fields(of: tokens)["$.expiration"], "Date(\(seconds))")
    }

    /// Test that the alias can't hide a changed value or key from the stored-format gate
    ///
    /// - Given: The `userPoolTokens` fixture and its fields in the locked manifest
    /// - When:
    ///    - The fixture is decoded as it is, with its `expiration` value changed, and with its `expiration` key
    ///      renamed, to `expiry` and to the property's name, `legacyExpiration`
    /// - Then:
    ///    - As it is, it dumps to the manifest's fields
    ///    - With the value changed, the dump differs from the manifest at `$.expiration`, and only there
    ///    - With either key, decoding throws `keyNotFound` for `expiration`, as the gate's decode does
    ///
    func testChangedKeyOrValueStillFailsTheGoldenComparison() throws {
        let manifest = try Self.manifestFields()
        XCTAssertEqual(try Self.dump(Self.tokensFixture()), manifest)

        let changedValue = try Self.editedFixture { object in
            object["expiration"] = try XCTUnwrap(object["expiration"] as? Double, "no expiration in the fixture") + 1
        }
        let changed = try Self.dump(changedValue)
        XCTAssertNotEqual(changed, manifest)
        XCTAssertNotEqual(changed["$.expiration"], manifest["$.expiration"])
        XCTAssertEqual(changed.filter { $0.key != "$.expiration" }, manifest.filter { $0.key != "$.expiration" })

        for renamed in ["expiry", "legacyExpiration"] {
            let data = try Self.editedFixture { object in
                object[renamed] = try XCTUnwrap(object.removeValue(forKey: "expiration"), "no expiration in the fixture")
            }
            XCTAssertThrowsError(try Self.dump(data), renamed) { error in
                guard case DecodingError.keyNotFound(let key, _) = error else {
                    return XCTFail("\(renamed): expected keyNotFound, got \(error)")
                }
                XCTAssertEqual(key.stringValue, "expiration", renamed)
            }
        }
    }
}
