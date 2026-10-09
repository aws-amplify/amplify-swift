//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoAuthPlugin
import CryptoKit
import Foundation

/// Shared plumbing for the golden baseline gates (stored format, error catalogue, log transcript).
///
/// Golden files live under `TestResources/` next to the test sources. They are read and written through
/// `#filePath` rather than `Bundle.module`, so the generators can write into the source tree and the
/// readers see exactly the committed bytes.
enum GoldenFiles {

    /// Set to `1` to (re)write golden files instead of comparing against them. The stored-format fixtures
    /// were written once, before the engine extraction, and must never be regenerated after that.
    static let generateEnvironmentKey = "AMPLIFY_GENERATE_GOLDEN"

    static var isGenerating: Bool {
        ProcessInfo.processInfo.environment[generateEnvironmentKey] == "1"
    }

    /// `AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests/TestResources`
    static var testResources: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // GoldenTests
            .deletingLastPathComponent() // AWSCognitoAuthPluginUnitTests
            .appendingPathComponent("TestResources", isDirectory: true)
    }

    static func directory(_ name: String) -> URL {
        testResources.appendingPathComponent(name, isDirectory: true)
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }

    /// Pretty, key-sorted JSON with a trailing newline: the format of every human-reviewed snapshot.
    static func snapshotData(_ value: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(value)
        data.append(contentsOf: Array("\n".utf8))
        return data
    }
}

/// The runtime's enum case-name lookup, which is what `print` uses for a payload-less case. Used instead
/// of `String(describing:)`, which prefers a type's own `description` / `debugDescription`.
@_silgen_name("swift_EnumCaseName")
private func _swiftEnumCaseName<T>(_ value: T) -> UnsafePointer<CChar>?

/// A flat, type-name-free view of a value's stored fields: `path → leaf`, built with `Mirror`.
///
/// This is the stored-format gate's "field-by-field" comparison. It does not use `==`, because
/// `AuthFlowType.==` tells `.custom` from `.customWithSRP` and `HostedUIOptions.==` includes the
/// presentation anchor, which is never persisted. Paths use property and case names only, never type
/// names, so a fork with the same shape (`EngineUserPoolTokens` for `AWSCognitoUserPoolTokens`) dumps
/// identically.
///
/// Each stored property is recorded under its encoded key, which is what the stored format pins. That is its
/// own name, except for the entries of `encodedKeyAliases`.
enum FieldDump {

    /// The stored properties whose name is not their encoded key, by type: property name to encoded key.
    ///
    /// A type's `CodingKeys` can't be read at run time (they are private to the type), so the exceptions are
    /// listed here, explicitly. Keep this table short, and add to it only when a property is renamed while its
    /// encoded key stays the same. `FieldDumpEncodedKeyTests` checks every entry against the type's encoder.
    ///
    /// - `AWSCognitoUserPoolTokens.legacyExpiration`: the public type stores the expiration as
    ///   `legacyExpiration` (its deprecated public `expiration` is computed from it) and encodes it under
    ///   `"expiration"` through its `CodingKeys`. The stored format records `expiration`, so the dump does too.
    static let encodedKeyAliases: [ObjectIdentifier: [String: String]] = [
        ObjectIdentifier(AWSCognitoUserPoolTokens.self): ["legacyExpiration": "expiration"]
    ]

    /// The name `label`, a stored property of `type`, is recorded under: its encoded key.
    static func recordedName(of label: String, in type: Any.Type) -> String {
        encodedKeyAliases[ObjectIdentifier(type)]?[label] ?? label
    }

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
        case let date as Date:
            fields[path] = "Date(\(date.timeIntervalSinceReferenceDate))"
            return
        case let data as Data:
            fields[path] = "Data(\(data.base64EncodedString()))"
            return
        case let double as Double:
            fields[path] = "\(double)"
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
                let name = child.label.map { recordedName(of: $0, in: type(of: value)) } ?? "\(index)"
                walk(child.value, path: "\(path).\(name)", into: &fields)
            }
        default:
            fields[path] = String(describing: value)
        }
    }
}

/// Key-order-independent JSON comparison.
///
/// `JSONEncoder` on Apple platforms does not write keyed containers in encode order. The order changes
/// from process to process, and even between two values of the same type in one process (measured
/// when the baselines were captured). So the stored-format gate compares
/// canonical forms: both sides are parsed and re-serialized with sorted keys. Everything except key
/// order is still compared exactly: key sets, `null` versus an absent key, strings, number spelling as
/// `JSONSerialization` normalizes it, and `true`/`false` versus `1`/`0`.
enum CanonicalJSON {

    static func canonicalize(_ data: Data) throws -> Data {
        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return try JSONSerialization.data(
            withJSONObject: object,
            options: [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]
        )
    }

    static func string(_ data: Data) -> String {
        String(data: (try? canonicalize(data)) ?? data, encoding: .utf8) ?? "<non-UTF-8 data>"
    }

    static func areEqual(_ lhs: Data, _ rhs: Data) throws -> Bool {
        try canonicalize(lhs) == canonicalize(rhs)
    }

    /// Whether the JSON holds an object with two or more keys anywhere, so a permuted variant differs.
    static func hasMultiKeyObject(_ data: Data) throws -> Bool {
        func check(_ value: Any) -> Bool {
            if let object = value as? [String: Any] {
                return object.count >= 2 || object.values.contains(where: check)
            }
            if let array = value as? [Any] {
                return array.contains(where: check)
            }
            return false
        }
        return try check(JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]))
    }

    /// The same JSON with every object's keys in reverse-sorted order, written as text. Leaves (strings,
    /// numbers, booleans, `null`) are written exactly as `canonicalize` writes them.
    static func reverseSortedText(_ data: Data) throws -> Data {
        func leaf(_ value: Any) throws -> String {
            let data = try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed, .withoutEscapingSlashes])
            return String(decoding: data, as: UTF8.self)
        }
        func write(_ value: Any) throws -> String {
            if let object = value as? [String: Any] {
                let members = try object.keys.sorted(by: >).map { key in
                    try "\(leaf(key)):\(write(object[key] as Any))"
                }
                return "{\(members.joined(separator: ","))}"
            }
            if let array = value as? [Any] {
                return try "[\(array.map(write).joined(separator: ","))]"
            }
            return try leaf(value)
        }
        let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return try Data(write(object).utf8)
    }
}
