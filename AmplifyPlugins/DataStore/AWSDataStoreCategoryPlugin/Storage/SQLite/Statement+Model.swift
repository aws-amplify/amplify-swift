//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite
import AWSPluginsCore

typealias ModelValues = [String: Any?]

/// Struct used to hold the values extracted from a executed `Statement`.
///
/// This type allows the results to be decoded into the actual models with a single call
/// instead of decoding each row individually. This keeps serialization of
/// large result sets efficient.
struct StatementResult<M: Model>: Decodable {

    let elements: [M]

    static func from(dictionary: ModelValues) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        return try decoder.decode(Self.self, from: data)
    }
}

/// Conforming to this protocol means that the `Statement` can be converted to an array of `Model`.
protocol StatementModelConvertible {

    /// Converts all the rows in the current executed `Statement` to the given `Model` type.
    ///
    /// - Parameters:
    ///   - modelType - the target `Model` type
    ///   - modelSchema - the schema for `Model`
    ///   - statement - the query executed that generated this result
    /// - Returns: an array of `Model` of the specified type
    func convert<M: Model>(to modelType: M.Type,
                           withSchema modelSchema: ModelSchema,
                           using statement: SelectStatement) throws -> [M]

}

/// Extend `Statement` with the model conversion capabilities defined by `StatementModelConvertible`.
extension Statement: StatementModelConvertible {

    var logger: Logger {
        Amplify.Logging.logger(forCategory: .dataStore)
    }

    func convert<M: Model>(to modelType: M.Type,
                           withSchema modelSchema: ModelSchema,
                           using statement: SelectStatement) throws -> [M] {
        var elements: [ModelValues] = []

        // parse each row of the result
        let iter = makeIterator()
        while let row = try iter.failableNext() {
            let modelDictionary = try convert(row: row, withSchema: modelSchema, using: statement)
            elements.append(modelDictionary)
        }

        let values: ModelValues = ["elements": elements]
        let result: StatementResult<M> = try StatementResult.from(dictionary: values)
        return result.elements
    }

    func convert(row: Element,
                 withSchema modelSchema: ModelSchema,
                 using statement: SelectStatement) throws -> ModelValues {
        let columnMapping = statement.metadata.columnMapping
        let modelDictionary = ([:] as ModelValues).mutableCopy()
        for (index, value) in row.enumerated() {
            let column = columnNames[index]
            guard let (schema, field) = columnMapping[column] else {
                logger.debug("""
                A column named \(column) was found in the result set but no field on
                \(modelSchema.name) could be found with that name and it will be ignored.
                """)
                continue
            }

            let modelValue = try SQLiteModelValueConverter.convertToSource(
                from: value,
                fieldType: field.type
            )
            modelDictionary.updateValue(modelValue, forKeyPath: column)

            // create lazy list for "many" relationships
            if let id = modelValue as? String, field.isPrimaryKey {
                let associations = schema.fields.values.filter {
                    $0.isArray && $0.hasAssociation
                }
                let prefix = column.replacingOccurrences(of: field.name, with: "")
                associations.forEach { association in
                    let associatedField = association.associatedField?.name
                    let lazyList = List<AnyModel>.lazyInit(associatedId: id,
                                                           associatedWith: associatedField)
                    let listKeyPath = prefix + association.name
                    modelDictionary.updateValue(lazyList, forKeyPath: listKeyPath)
                }
            }
        }
        // swiftlint:disable:next force_cast
        return modelDictionary as! ModelValues
    }

}

internal extension List {

    /// Creates a data structure that is capable of initializing a `List<M>` with
    /// lazy-load capabilities when the list is being decoded.
    ///
    /// See the `List.init(from:Decoder)` for details.
    static func lazyInit(associatedId: String, associatedWith: String?) -> [String: Any?] {
        return [
            "associatedId": associatedId,
            "associatedField": associatedWith,
            "elements": []
        ]
    }
}

private extension Dictionary where Key == String, Value == Any? {

    /// Utility to create a `NSMutableDictionary` from a Swift `Dictionary<String, Any?>`.
    func mutableCopy() -> NSMutableDictionary {
        // swiftlint:disable:next force_cast
        return (self as NSDictionary).mutableCopy() as! NSMutableDictionary
    }
}

/// Extension that adds utilities to created nested values in a dictionary
/// from a `keyPath` notation (e.g. `root.with.some.nested.prop`.
private extension NSMutableDictionary {

    /// Utility to allows Swift standard types to be used in `setObject`
    /// of the `NSMutableDictionary`.
    ///
    /// - Parameters:
    ///   - value: the value to be set
    ///   - key: the key as a `String`
    func updateValue(_ value: Value?, forKey key: String) {
        let object = value == nil ? NSNull() : value as Any
        setObject(object, forKey: key as NSString)
    }

    /// Utility that enables the automatic creation of nested dictionaries when
    /// a `keyPath` is passed, even if no existing value is set in that `keyPath`.
    ///
    /// This function will auto-create nested structures and set the value accordingly.
    ///
    /// - Example
    ///
    /// ```swift
    /// let dict = [:].mutableCopy()
    /// dict.updateValue(1, "some.nested.value")
    ///
    /// // dict now is
    /// [
    ///     "some": [
    ///         "nested": [
    ///             "value": 1
    ///         ]
    ///     ]
    /// ]
    /// ```
    ///
    /// - Parameters:
    ///   - value: the value to be set
    ///   - keyPath: the key path as a `String` (e.g. "nested.key")
    func updateValue(_ value: Value?, forKeyPath keyPath: String) {
        if keyPath.firstIndex(of: ".") == nil {
            updateValue(value, forKey: keyPath)
        }
        let keyComponents = keyPath.components(separatedBy: ".")
        var current = self
        for (index, key) in keyComponents.enumerated() {
            let isLast = index == keyComponents.endIndex - 1
            if isLast {
                current.updateValue(value, forKey: key)
            } else if let nested = current[key] as? NSMutableDictionary {
                current = nested
            } else {
                let nested: NSMutableDictionary = [:]
                current.updateValue(nested, forKey: key)
                current = nested
            }
        }
    }

}
