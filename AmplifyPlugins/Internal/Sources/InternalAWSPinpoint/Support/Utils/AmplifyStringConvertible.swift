//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Conforming to this protocol automatically adds support to "prettify" the type when printing its value.
protocol AmplifyStringConvertible: CustomStringConvertible {}

extension AmplifyStringConvertible {
    public var description: String {
        return prettyDescription(for: self)
    }

    private func prettyDescription(
        for object: Any,
        level: UInt = 1
    ) -> String {
        return prettyDescription(for: object, level: level) { result, indentation in
            switch object {
            case let dictionary as Dictionary<AnyHashable, Any>:
                // Dictionaries follow the format: "<key>": <value>
                for (key, value) in dictionary {
                    result.append(
                        contentsOf: "\n\(indentation)\"\(key)\": \(description(for: value, withLevel: level)),"
                    )
                }
            case let collection as any Collection:
                // Other collections follow the format: <value_1>, <value_2>, ..., <value_n>
                for value in collection {
                    result.append(contentsOf: "\n\(indentation)\(description(for: value, withLevel: level)),")
                }
            default:
                // Other objects follow the format: <attribute>: <value>
                for child in Mirror(reflecting: object).children {
                    guard let label = child.label else { continue }
                    result.append(
                        contentsOf: "\n\(indentation)\(label): \(description(for: child.value, withLevel: level)),"
                    )
                }
            }
        }
    }

    private func prettyDescription(
        for object: Any,
        level: UInt = 1,
        contentsBuilder: (_ result: inout String, _ indentation: String) -> Void
    ) -> String {
        var contents = ""
        contentsBuilder(&contents, indentation(forLevel: level))
        if contents.isEmpty {
            return emptyDescription(for: object)
        }

        let tags = tags(for: object)
        return appendClosingTag(
            tags.closing,
            to: tags.opening.appending(contents),
            currentLevel: level
        )
    }

    private func description(
        for value: Any,
        withLevel level: UInt
    ) -> String {
        let unwrappedValue = unwrappedValue(from: value)
        switch unwrappedValue {
        case let stringValue as String:
            return stringValue.quoted
        case is Int, is Bool, is Double, is Date, is Float:
            return "\(unwrappedValue)"
        case is any CaseIterable, is any RawRepresentable:
            return ".\(unwrappedValue)"
        default:
            // When the value is another object, add one level of identation
            return prettyDescription(for: unwrappedValue, level: level + 1)
        }
    }

    private func unwrappedValue(from value: Any) -> Any {
        // This is to avoid printing optionals with the "Optional(x)" format,
        // instead we just print "nil" or their actual values.
        if let optional = value as? _AmplifyOptional {
            return optional._amplifyUnwrap() ?? "nil"
        }
        return value
    }

    private func indentation(forLevel level: UInt) -> String {
        return String(repeating: " ", count: 4 * Int(level))
    }

    private func tags(for object: Any) -> (opening: String, closing: String) {
        switch object {
        case is any Collection:
            return (opening: "[", closing: "]")
        default:
            return (opening: "{", closing: "}")
        }
    }

    private func emptyDescription(for object: Any) -> String {
        switch object {
        case is Dictionary<AnyHashable, Any>:
            return "[:]"
        case is any Collection:
            return "[]"
        default:
            return "{}"
        }
    }

    private func appendClosingTag(
        _ tag: String,
        to value: String,
        currentLevel level: UInt
    ) -> String {
        // Remove the last comma
        let result = value.hasSuffix(",") ? String(value.dropLast()) : value
        // As we're adding a closing tag, reduce one indentation level
        return result.appending("\n\(indentation(forLevel: level - 1))\(tag)")
    }
}

// swiftlint:disable identifier_name
private protocol _AmplifyOptional {
    func _amplifyUnwrap() -> Any?
}

extension Optional: _AmplifyOptional {
    func _amplifyUnwrap() -> Any? {
        switch self {
        case .none:
            return nil
        case .some(let wrapped):
            return wrapped
        }
    }
}

private extension String {
    var quoted: String {
        // Don't quote the String representing nil
        if self == "nil" { return self }
        return "\"\(self)\""
    }
}
