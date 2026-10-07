//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CryptoKit
import Foundation

/// The plugin's configuration goldens, read in place from
/// `AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests/TestResources/GoldenConfiguration/`.
///
/// They are read, not copied: the directory is locked (`scripts/cognito-engine/check_fixture_lock.sh`, CODEOWNERS), so
/// one pinned source serves both tests, and a copy would need a lock of its own. `manifest.json` is pinned
/// here to the SHA-256 the plugin's `ConfigurationGoldenTests` pins, and every file read is checked against
/// the manifest.
///
/// Only the `amplify_outputs/` fixtures are read (the plugin's `outputsNames`). The `gen1-*` fixtures pin
/// the plugin's Gen1 path, and the client does not accept Gen1 configuration.
enum PluginGoldenConfiguration {

    /// `ConfigurationGoldenTests.pinnedManifestSHA256`.
    static let pinnedManifestSHA256 = "7be1ed67381363d9a71e7f6ffd50a59c9e77771bd6929be2d44d9c38cb550310"

    /// `ConfigurationGoldenTests.outputsNames`.
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

    struct Manifest: Decodable {
        struct Entry: Decodable {
            let name: String
            let input: String
            let inputSHA256: String
            let file: String
            let sha256: String
            let configurationCase: String
            let expectedFields: [String: String]
        }

        let fixtures: [Entry]
    }

    static var directory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // PluginGoldenConfiguration.swift
            .deletingLastPathComponent() // Support
            .deletingLastPathComponent() // UnitTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // AmplifyCognitoClient
            .deletingLastPathComponent() // AmplifyClients
            .appendingPathComponent(
                "AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests/TestResources/GoldenConfiguration",
                isDirectory: true
            )
    }

    static func data(_ relativePath: String) throws -> Data {
        try Data(contentsOf: directory.appendingPathComponent(relativePath))
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func manifestData() throws -> Data {
        try data("manifest.json")
    }

    /// The manifest's `amplify_outputs` entries, by name. Gen1 entries are dropped unread.
    static func outputsEntries() throws -> [String: Manifest.Entry] {
        let manifest = try JSONDecoder().decode(Manifest.self, from: manifestData())
        let entries = manifest.fixtures.filter { $0.input.hasPrefix("amplify_outputs/") }
        return Dictionary(uniqueKeysWithValues: entries.map { ($0.name, $0) })
    }
}

/// Key-order-independent JSON: parsed and re-serialized with sorted keys, as the plugin's `CanonicalJSON`.
enum CanonicalJSON {
    static func canonicalize(_ object: Any) throws -> Data {
        try JSONSerialization.data(
            withJSONObject: object,
            options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]
        )
    }

    static func canonicalize(_ data: Data) throws -> Data {
        try canonicalize(JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]))
    }
}

/// The runtime's enum case-name lookup, as the plugin's `FieldDump` uses it.
@_silgen_name("swift_EnumCaseName")
private func _swiftEnumCaseName<T>(_ value: T) -> UnsafePointer<CChar>?

/// A copy of the plugin's `FieldDump` (`GoldenTests/GoldenFileSupport.swift`): a flat `path → leaf` view of a
/// value's stored fields, by property and case name only, never type name. Values with the same shape and
/// names dump identically, which is what lets the client's `EngineConfigurationInput` be compared with the
/// `AuthConfiguration` fields the plugin recorded in the manifest.
enum FieldDump {

    static func fields(of value: Any) -> [String: String] {
        var fields: [String: String] = [:]
        walk(value, path: "$", into: &fields)
        return fields
    }

    static func caseName(of value: Any) -> String {
        func open<T>(_ value: T) -> String {
            _swiftEnumCaseName(value).map { String(cString: $0) } ?? String(describing: value)
        }
        return _openExistential(value, do: open)
    }

    private static func walk(_ value: Any, path: String, into fields: inout [String: String]) {
        switch value {
        case let string as String:
            fields[path] = "\"\(string)\""
            return
        case let bool as Bool:
            fields[path] = bool ? "true" : "false"
            return
        case let integer as any BinaryInteger:
            fields[path] = "\(integer)"
            return
        default:
            break
        }

        let mirror = Mirror(reflecting: value)
        switch mirror.displayStyle {
        case .optional:
            if let wrapped = mirror.children.first {
                walk(wrapped.value, path: path, into: &fields)
            } else {
                fields[path] = "nil"
            }
        case .enum:
            if let payload = mirror.children.first {
                walk(payload.value, path: "\(path).\(payload.label ?? caseName(of: value))", into: &fields)
            } else {
                fields[path] = ".\(caseName(of: value))"
            }
        case .collection, .set:
            let children = Array(mirror.children)
            fields["\(path).count"] = "\(children.count)"
            for (index, child) in children.enumerated() {
                walk(child.value, path: "\(path)[\(index)]", into: &fields)
            }
        case .struct, .class, .tuple:
            let children = Array(mirror.children)
            if children.isEmpty {
                fields[path] = "{}"
            }
            for (index, child) in children.enumerated() {
                walk(child.value, path: "\(path).\(child.label ?? "\(index)")", into: &fields)
            }
        default:
            fields[path] = String(describing: value)
        }
    }
}
