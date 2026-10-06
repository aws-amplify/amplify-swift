//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Configuration parity: the client builds the same engine configuration
/// from each `amplify_outputs` golden input as the plugin's `ConfigurationHelper` recorded.
///
/// Reads the `amplify_outputs/` fixtures only (`PluginGoldenConfiguration.outputsNames`), never the Gen1
/// ones: the client does not accept Gen1 configuration.
final class AuthClientConfigurationParityTests: XCTestCase {

    private func clientConfiguration(_ name: String) throws -> AuthClientConfiguration {
        try AuthClientConfiguration(
            outputsData: PluginGoldenConfiguration.data("amplify_outputs/\(name).json"),
            resourceName: name
        )
    }

    /// Test that the client reads the locked goldens and only their `amplify_outputs` half
    ///
    /// - Given: The plugin's `GoldenConfiguration/manifest.json`
    /// - When:
    ///    - Its SHA-256 is computed, and its `amplify_outputs` entries are listed
    /// - Then:
    ///    - The SHA-256 is the one the plugin's `ConfigurationGoldenTests` pins
    ///    - The entries are exactly `outputsNames`, and every input and golden file matches its recorded SHA-256
    ///
    func testReadsThePinnedAmplifyOutputsGoldens() throws {
        XCTAssertEqual(
            try PluginGoldenConfiguration.sha256Hex(PluginGoldenConfiguration.manifestData()),
            PluginGoldenConfiguration.pinnedManifestSHA256
        )
        let entries = try PluginGoldenConfiguration.outputsEntries()
        XCTAssertEqual(entries.keys.sorted(), PluginGoldenConfiguration.outputsNames.sorted())
        for name in PluginGoldenConfiguration.outputsNames {
            let entry = try XCTUnwrap(entries[name], name)
            XCTAssertEqual(entry.input, "amplify_outputs/\(name).json")
            XCTAssertEqual(
                try PluginGoldenConfiguration.sha256Hex(PluginGoldenConfiguration.data(entry.input)),
                entry.inputSHA256,
                "\(entry.input) changed"
            )
            XCTAssertEqual(
                try PluginGoldenConfiguration.sha256Hex(PluginGoldenConfiguration.data(entry.file)),
                entry.sha256,
                "\(entry.file) changed"
            )
        }
    }

    /// Test that every field the client derives equals the field the plugin recorded, nils included
    ///
    /// - Given: Every `amplify_outputs` golden input, and the manifest's `expectedFields`: the plugin's
    ///   `AuthConfiguration`, dumped field by field with `FieldDump`
    /// - When:
    ///    - The client decodes the input and derives its `EngineConfigurationInput`, dumped the same way
    /// - Then:
    ///    - The case and every path and value are equal: all twelve `UserPoolConfigurationData` fields and
    ///      both `IdentityPoolConfigurationData` fields
    ///
    func testEveryFieldMatchesThePluginsRecordedValue() throws {
        let entries = try PluginGoldenConfiguration.outputsEntries()
        for name in PluginGoldenConfiguration.outputsNames {
            let entry = try XCTUnwrap(entries[name], name)
            let input = try clientConfiguration(name).engineInput
            XCTAssertEqual(FieldDump.caseName(of: input), entry.configurationCase, name)

            let actual = FieldDump.fields(of: input)
            for (path, expected) in entry.expectedFields.sorted(by: { $0.key < $1.key }) {
                XCTAssertEqual(actual[path], expected, "\(name): \(path)")
            }
            let extra = Set(actual.keys).subtracting(entry.expectedFields.keys)
            XCTAssertTrue(extra.isEmpty, "\(name): fields the plugin does not have: \(extra.sorted())")
        }
    }

    /// Test that the engine configuration the client builds encodes to each golden tree
    ///
    /// - Given: Every `amplify_outputs` golden input, and its golden `<name>.json`: the plugin's
    ///   `AuthConfiguration` encoded with `JSONEncoder()`
    /// - When:
    ///    - The client builds the engine's `AuthConfiguration` from the input (`AuthConfiguration(client:)`)
    ///      and encodes it with `JSONEncoder()`
    /// - Then:
    ///    - The two trees are equal, in canonical form
    ///
    func testEveryFixtureMatchesTheGoldenTree() throws {
        for name in PluginGoldenConfiguration.outputsNames {
            let built = try AuthConfiguration(client: clientConfiguration(name))
            let expected = try CanonicalJSON.canonicalize(PluginGoldenConfiguration.data("\(name).json"))
            let actual = try CanonicalJSON.canonicalize(JSONEncoder().encode(built))
            XCTAssertEqual(
                String(decoding: actual, as: UTF8.self),
                String(decoding: expected, as: UTF8.self),
                name
            )
        }
    }

    /// Test that each golden decodes to exactly the engine configuration the client builds
    ///
    /// - Given: Every `amplify_outputs` golden input, and its golden `<name>.json`
    /// - When:
    ///    - The golden is decoded as the engine's `AuthConfiguration`, and the client builds one from the input
    /// - Then:
    ///    - The two are equal by the engine's own `==`, which compares every field
    ///
    func testEveryGoldenDecodesToTheBuiltConfiguration() throws {
        for name in PluginGoldenConfiguration.outputsNames {
            let built = try AuthConfiguration(client: clientConfiguration(name))
            let golden = try JSONDecoder().decode(AuthConfiguration.self, from: PluginGoldenConfiguration.data("\(name).json"))
            XCTAssertEqual(built, golden, name)
        }
    }

    /// Test that the engine input has a field for every engine configuration field, and no other
    ///
    /// - Given: The field names the plugin recorded for its `UserPoolConfigurationData` and
    ///   `IdentityPoolConfigurationData` (every manifest entry records all of them, nils included)
    /// - When:
    ///    - They are compared with the stored properties of `EngineUserPoolSettings` and
    ///      `EngineIdentityPoolSettings`
    /// - Then:
    ///    - The names are the same, so an engine field the client does not fill fails here
    ///
    func testEngineInputCoversEveryEngineField() throws {
        let entry = try XCTUnwrap(PluginGoldenConfiguration.outputsEntries()["full"])
        func recordedFields(_ prefix: String) -> Set<String> {
            Set(entry.expectedFields.keys.compactMap { path in
                guard path.hasPrefix(prefix) else { return nil }
                return String(path.dropFirst(prefix.count).prefix { $0 != "." && $0 != "[" })
            })
        }
        func storedFields(_ value: Any) -> Set<String> {
            Set(Mirror(reflecting: value).children.compactMap(\.label))
        }
        guard case let .userPoolsAndIdentityPools(userPool, identityPool) = try clientConfiguration("full").engineInput else {
            return XCTFail("full has both pools")
        }
        XCTAssertEqual(storedFields(userPool), recordedFields("$.userPoolsAndIdentityPools..0."))
        XCTAssertEqual(storedFields(userPool).count, 12)
        XCTAssertEqual(storedFields(identityPool), recordedFields("$.userPoolsAndIdentityPools..1."))
    }
}
