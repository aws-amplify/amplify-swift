//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

/// The configuration golden: what the plugin builds from each configuration input, pinned.
///
/// Each input in `TestResources/GoldenConfiguration/amplify_outputs/` is an `amplify_outputs.json`, and each
/// in `amplifyconfiguration/` a Gen1 `amplifyconfiguration.json`. The plugin decodes it as `Amplify.configure`
/// does, builds `AuthConfiguration` with `ConfigurationHelper` (the `JSONValue` path for Gen1), and the
/// result's `JSONEncoder()` encoding must be tree-equal to `<name>.json`. The manifest records every field of
/// the built value (`FieldDump`), nils included.
///
/// The golden files were generated before the engine's environment factory replaced the plugin's own
/// configuration code, from the code as it was then. The Gen1 inputs and `oauth-noSignInRedirect` were added
/// later, with no production change and with every earlier golden byte-identical. They must not be
/// regenerated.
///
/// The Cognito client's configuration parity test reads the `amplify_outputs/` fixtures only (`outputsNames`),
/// never `names` or every manifest entry. The Gen1 fixtures (`gen1Names`) pin the plugin's `JSONValue`
/// configuration path only: the client does not accept Gen1 configuration.
final class ConfigurationGoldenTests: XCTestCase {

    /// SHA-256 of `manifest.json`. Changing any golden file changes the manifest, which changes this value.
    static let pinnedManifestSHA256 = "7be1ed67381363d9a71e7f6ffd50a59c9e77771bd6929be2d44d9c38cb550310"

    static var directory: URL { GoldenFiles.directory("GoldenConfiguration") }

    static var inputDirectory: URL { directory.appendingPathComponent("amplify_outputs", isDirectory: true) }

    static var gen1InputDirectory: URL { directory.appendingPathComponent("amplifyconfiguration", isDirectory: true) }

    /// The fixtures, by name: `outputsNames` then `gen1Names`.
    static var names: [String] { outputsNames + gen1Names }

    /// `amplify_outputs/<name>.json` is the input and `<name>.json` the golden.
    static let outputsNames = [
        "full",
        "oauth",
        "oauth-noSignInRedirect",
        "oauth-noSignOutRedirect",
        "passwordPolicy-all",
        "passwordPolicy-none",
        "standardRequiredAttributes-all",
        "userPool-minimal",
        "userPoolAndIdentityPool",
        "usernameAttributes",
        "userVerificationTypes"
    ]

    /// `amplifyconfiguration/<name>.json` is the input (Gen1, the `JSONValue` path) and `<name>.json` the golden.
    /// Plugin only: the client does not accept Gen1 configuration, so its parity test must not read these.
    static let gen1Names = [
        "gen1-customAuth",
        "gen1-full",
        "gen1-identityPoolOnly",
        "gen1-migrationEnabled"
    ]

    /// The `UserPoolConfigurationData` fields `amplify_outputs` can fill. Each must hold a non-empty value in
    /// at least one fixture. The other three (`endpoint`, `clientSecret`, `pinpointAppId`) have no
    /// `amplify_outputs` key and are always `nil` on this path, which every manifest entry records.
    static let fillableUserPoolFields = [
        "poolId", "clientId", "region", "authFlowType", "hostedUIConfig", "passwordProtectionSettings",
        "usernameAttributes", "signUpAttributes", "verificationMechanisms"
    ]

    /// The `UserPoolConfigurationData` fields the Gen1 `JSONValue` path can fill. It never fills
    /// `passwordProtectionSettings`, `usernameAttributes`, `signUpAttributes` or `verificationMechanisms`.
    static let gen1FillableUserPoolFields = [
        "poolId", "clientId", "region", "endpoint", "clientSecret", "pinpointAppId", "authFlowType", "hostedUIConfig"
    ]

    struct Manifest: Codable, Equatable {
        struct Entry: Codable, Equatable {
            let name: String
            let input: String
            let inputSHA256: String
            let file: String
            let sha256: String
            /// The `AuthConfiguration` case built from the input.
            let configurationCase: String
            /// The built value, field by field (`FieldDump`).
            let expectedFields: [String: String]
        }

        let note: String
        let encoder: String
        let fixtures: [Entry]
    }

    /// The input's path relative to `directory`, as the manifest records it.
    static func inputPath(_ name: String) -> String {
        gen1Names.contains(name) ? "amplifyconfiguration/\(name).json" : "amplify_outputs/\(name).json"
    }

    static func inputData(_ name: String) throws -> Data {
        try Data(contentsOf: directory.appendingPathComponent(inputPath(name)))
    }

    static func goldenData(_ name: String) throws -> Data {
        try Data(contentsOf: directory.appendingPathComponent("\(name).json"))
    }

    static func loadManifest() throws -> Manifest {
        let data = try Data(contentsOf: directory.appendingPathComponent("manifest.json"))
        return try JSONDecoder().decode(Manifest.self, from: data)
    }

    /// What the plugin does with an `amplify_outputs.json`: `AmplifyOutputs.data(_:)`'s decode, then
    /// `ConfigurationHelper.authConfiguration(_:)`, as `AWSCognitoAuthPlugin.configure(using:)` calls it. For a
    /// Gen1 input: `AmplifyConfiguration`'s decode, then the `awsCognitoAuthPlugin` `JSONValue` that
    /// `Amplify.configure` hands the plugin, through `ConfigurationHelper.authConfiguration(_:)`.
    static func buildConfiguration(_ name: String) throws -> AuthConfiguration {
        if gen1Names.contains(name) {
            let configuration = try AmplifyConfiguration.decodeAmplifyConfiguration(from: inputData(name))
            let plugin = try XCTUnwrap(configuration.auth?.plugins["awsCognitoAuthPlugin"], name)
            return try ConfigurationHelper.authConfiguration(plugin)
        }
        let outputs = try AmplifyOutputsData.decodeAmplifyOutputsData(from: inputData(name))
        return try ConfigurationHelper.authConfiguration(outputs)
    }

    override func setUpWithError() throws {
        try XCTSkipIf(GoldenFiles.isGenerating, "Generating golden files")
    }

    /// Test that the manifest is the one committed with the goldens, extended with the later fixtures
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

    /// Test that the inputs, the goldens, the manifest and the list in code agree
    ///
    /// - Given: The two fixture directories, the manifest and `names`
    /// - When:
    ///    - They are compared
    /// - Then:
    ///    - They list the same fixtures, and every file's SHA-256 matches the manifest
    ///
    func testFixturesMatchManifest() throws {
        let manifest = try Self.loadManifest()
        func jsonFiles(_ url: URL) throws -> Set<String> {
            try Set(
                FileManager.default.contentsOfDirectory(atPath: url.path)
                    .filter { $0.hasSuffix(".json") && $0 != "manifest.json" }
            )
        }
        XCTAssertEqual(Set(manifest.fixtures.map(\.file)), try jsonFiles(Self.directory))
        XCTAssertEqual(
            Set(manifest.fixtures.map(\.input)),
            try Set(jsonFiles(Self.inputDirectory).map { "amplify_outputs/\($0)" })
                .union(jsonFiles(Self.gen1InputDirectory).map { "amplifyconfiguration/\($0)" })
        )
        for entry in manifest.fixtures {
            XCTAssertEqual(entry.input, Self.inputPath(entry.name), entry.name)
        }
        XCTAssertEqual(manifest.fixtures.map(\.name).sorted(), Self.names.sorted())
        for entry in manifest.fixtures {
            XCTAssertEqual(try GoldenFiles.sha256Hex(Self.goldenData(entry.name)), entry.sha256, "\(entry.file) changed")
            XCTAssertEqual(try GoldenFiles.sha256Hex(Self.inputData(entry.name)), entry.inputSHA256, "\(entry.input) changed")
        }
    }

    /// Test that each `amplify_outputs` input still builds the recorded configuration, field by field
    ///
    /// - Given: Every `amplify_outputs` input
    /// - When:
    ///    - It is decoded and passed through `ConfigurationHelper.authConfiguration(_:)`
    /// - Then:
    ///    - The built `AuthConfiguration` has the recorded case and every recorded field, nils included
    ///
    func testEveryInputBuildsTheRecordedFields() throws {
        let entries = try Dictionary(uniqueKeysWithValues: Self.loadManifest().fixtures.map { ($0.name, $0) })
        for name in Self.names {
            let entry = try XCTUnwrap(entries[name], name)
            let configuration = try Self.buildConfiguration(name)
            XCTAssertEqual(FieldDump.caseName(of: configuration), entry.configurationCase, name)
            assertFields(FieldDump.fields(of: configuration), entry.expectedFields, "\(name) vs manifest")
        }
    }

    /// Test that the built configuration encodes to its golden tree
    ///
    /// - Given: Every `amplify_outputs` input
    /// - When:
    ///    - The built `AuthConfiguration` is encoded with the production encoder, `JSONEncoder()`
    /// - Then:
    ///    - The encoding is tree-equal to `<name>.json` (key order ignored, `null` versus absent kept)
    ///
    func testBuiltConfigurationEncodesToTheGoldenTree() throws {
        for name in Self.names {
            let encoded = try JSONEncoder().encode(Self.buildConfiguration(name))
            let golden = try Self.goldenData(name)
            XCTAssertTrue(
                try CanonicalJSON.areEqual(encoded, golden),
                "\(name): \(CanonicalJSON.string(encoded)) != \(CanonicalJSON.string(golden))"
            )
        }
    }

    /// Test that each golden decodes back to the configuration built from its input
    ///
    /// - Given: Every golden file
    /// - When:
    ///    - It is decoded with `JSONDecoder()`, with no `try?` in the path
    /// - Then:
    ///    - The decoded value equals the built one, by `==` and field by field
    ///
    func testGoldenDecodesToTheBuiltConfiguration() throws {
        for name in Self.names {
            let decoded = try JSONDecoder().decode(AuthConfiguration.self, from: Self.goldenData(name))
            let built = try Self.buildConfiguration(name)
            XCTAssertEqual(decoded, built, name)
            assertFields(FieldDump.fields(of: decoded), FieldDump.fields(of: built), "\(name) decoded vs built")
        }
    }

    /// Test that the fixtures exercise every `UserPoolConfigurationData` field each input format can fill
    ///
    /// - Given: The manifest's recorded fields for every fixture
    /// - When:
    ///    - The user-pool fields are collected, per input format
    /// - Then:
    ///    - Every stored property of `UserPoolConfigurationData` is recorded in each user-pool fixture
    ///    - Every field the format can fill holds a non-empty value in at least one of its fixtures
    ///    - A Gen1 fixture records an `authFlowType` other than the `.userSRP` default, and one records the
    ///      identity-pool-only case that `amplify_outputs` cannot express
    ///
    func testFixturesCoverEveryUserPoolField() throws {
        let storedProperties = Mirror(reflecting: UserPoolConfigurationData(poolId: "", clientId: "", region: ""))
            .children.compactMap(\.label)
        XCTAssertEqual(storedProperties.count, 12)

        let fixtures = try Self.loadManifest().fixtures
        let outputs = fixtures.filter { Self.outputsNames.contains($0.name) }
        let gen1 = fixtures.filter { Self.gen1Names.contains($0.name) }
        XCTAssertEqual(try filledUserPoolFields(outputs, storedProperties), Set(Self.fillableUserPoolFields))
        XCTAssertEqual(try filledUserPoolFields(gen1, storedProperties), Set(Self.gen1FillableUserPoolFields))
        XCTAssertTrue(gen1.contains { entry in
            entry.expectedFields.contains { $0.key.hasSuffix(".authFlowType") && $0.value != ".userSRP" }
        })
        XCTAssertTrue(gen1.contains { $0.configurationCase == "identityPools" })
    }

    private func filledUserPoolFields(
        _ fixtures: [Manifest.Entry],
        _ storedProperties: [String]
    ) throws -> Set<String> {
        var filled: Set<String> = []
        for entry in fixtures where entry.configurationCase != "identityPools" {
            // The user pool's path prefix: `verificationMechanisms` is a field of `UserPoolConfigurationData` only.
            let anchor = "verificationMechanisms.count"
            let anchorKey = try XCTUnwrap(entry.expectedFields.keys.first { $0.hasSuffix(anchor) }, entry.name)
            let prefix = String(anchorKey.dropLast(anchor.count))
            for property in storedProperties {
                let values = entry.expectedFields.filter {
                    $0.key == prefix + property || $0.key.hasPrefix(prefix + property + ".")
                        || $0.key.hasPrefix(prefix + property + "[")
                }
                XCTAssertFalse(values.isEmpty, "\(entry.name) does not record \(property)")
                let isEmpty = values.allSatisfy { $0.value == "nil" || ($0.key.hasSuffix(".count") && $0.value == "0") }
                if !isEmpty {
                    filled.insert(property)
                }
            }
        }
        return filled
    }

    /// Test that an `amplify_outputs` with no `auth` section is still rejected
    ///
    /// - Given: An `amplify_outputs.json` with only a version
    /// - When:
    ///    - `ConfigurationHelper.authConfiguration(_:)` is called with it
    /// - Then:
    ///    - It throws `AuthError.configuration`
    ///
    func testOutputsWithoutAuthAreRejected() throws {
        let outputs = try AmplifyOutputsData.decodeAmplifyOutputsData(from: Data(#"{"version":"1"}"#.utf8))
        XCTAssertThrowsError(try ConfigurationHelper.authConfiguration(outputs)) { error in
            guard case AuthError.configuration = error else {
                return XCTFail("Expected AuthError.configuration, got \(error)")
            }
        }
    }
}

/// Writes the goldens and the manifest from the `amplify_outputs` inputs. Runs only with
/// `AMPLIFY_GENERATE_GOLDEN=1`:
///
///     AMPLIFY_GENERATE_GOLDEN=1 swift test --filter ConfigurationGoldenGenerator
///
/// It refuses to overwrite an existing manifest unless `AMPLIFY_GOLDEN_OVERWRITE_FROZEN=1` is also set. The
/// inputs are hand-written.
final class ConfigurationGoldenGenerator: XCTestCase {

    func testGenerateConfigurationGoldens() throws {
        try XCTSkipUnless(GoldenFiles.isGenerating, "Set AMPLIFY_GENERATE_GOLDEN=1 to generate")
        let directory = ConfigurationGoldenTests.directory
        let manifestURL = directory.appendingPathComponent("manifest.json")
        if FileManager.default.fileExists(atPath: manifestURL.path),
           ProcessInfo.processInfo.environment["AMPLIFY_GOLDEN_OVERWRITE_FROZEN"] != "1" {
            throw XCTSkip("manifest.json exists; the S7 goldens are frozen")
        }

        var entries: [ConfigurationGoldenTests.Manifest.Entry] = []
        for name in ConfigurationGoldenTests.names {
            let configuration = try ConfigurationGoldenTests.buildConfiguration(name)
            var golden = try CanonicalJSON.canonicalize(JSONEncoder().encode(configuration))
            golden.append(contentsOf: Array("\n".utf8))
            try GoldenFiles.write(golden, to: directory.appendingPathComponent("\(name).json"))
            try entries.append(.init(
                name: name,
                input: ConfigurationGoldenTests.inputPath(name),
                inputSHA256: GoldenFiles.sha256Hex(ConfigurationGoldenTests.inputData(name)),
                file: "\(name).json",
                sha256: GoldenFiles.sha256Hex(golden),
                configurationCase: FieldDump.caseName(of: configuration),
                expectedFields: FieldDump.fields(of: configuration)
            ))
        }
        let manifest = ConfigurationGoldenTests.Manifest(
            note: """
            M2 S7 configuration goldens: the AuthConfiguration that ConfigurationHelper builds from each \
            amplify_outputs or Gen1 amplifyconfiguration input, encoded with JSONEncoder() and written in \
            canonical form (sorted keys). Compared as JSON trees. Generated before any S7 production change; \
            the Gen1 and oauth-noSignInRedirect fixtures were added later with no production change. Never \
            regenerate. The client parity test reads the amplify_outputs fixtures only; the gen1-* fixtures \
            pin the plugin's JSONValue path only, because the client does not accept Gen1 configuration.
            """,
            encoder: "JSONEncoder()",
            fixtures: entries
        )
        try GoldenFiles.write(GoldenFiles.snapshotData(manifest), to: manifestURL)
    }
}
