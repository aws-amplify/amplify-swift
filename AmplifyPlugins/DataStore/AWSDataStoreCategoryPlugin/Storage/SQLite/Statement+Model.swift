//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

typealias ModelValues = [String: Any?]

typealias ConvertCache = [String: ModelValues]

/// Struct used to hold the values extracted from a executed `Statement`.
///
/// This type allows the results to be decoded into the actual models with a single call
/// instead of decoding each row individually. This keeps serialization of
/// large result sets efficient.
struct StatementResult<M: Model>: Decodable {

    let elements: [M]

    public static func from(dictionary: ModelValues) throws -> Self {
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
    ///   - statement - the query executed that generated this result
    /// - Returns: an array of `Model` of the specified type
    func convert<M: Model>(to modelType: M.Type,
                           using statement: SelectStatement) throws -> [M]

}

/// Extend `Statement` with the model conversion capabilities defined by `StatementModelConvertible`.
extension Statement: StatementModelConvertible {

    var logger: Logger {
        Amplify.Logging.logger(forCategory: .dataStore)
    }

    func convert<M: Model>(to modelType: M.Type,
                           using statement: SelectStatement) throws -> [M] {
        var elements: [ModelValues] = []

        // parse each row of the result
        for row in self {
            let modelDictionary = try convert(row: row, to: modelType, using: statement)
            elements.append(modelDictionary)
        }

        let values: ModelValues = ["elements": elements]
        let result: StatementResult<M> = try StatementResult.from(dictionary: values)
        return result.elements
    }

    func convert(row: Element,
                 to modelType: Model.Type,
                 using statement: SelectStatement) throws -> ModelValues {
        let columnMapping = statement.metadata.columnMapping
        let modelDictionary = ([:] as ModelValues).mutableCopy()
        for (index, value) in row.enumerated() {
            let column = columnNames[index]
            guard let (schema, field) = columnMapping[column] else {
                logger.debug("""
                A column named \(column) was found in the result set but no field on
                \(modelType.modelName) could be found with that name and it will be ignored.
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
                let prefix = field.name.replacingOccurrences(of: field.name, with: "")
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

    static func lazyInit(associatedId: String, associatedWith: String?) -> [String: Any?] {
        return [
            "associatedId": associatedId,
            "associatedField": associatedWith,
            "elements": []
        ]
    }
}

internal extension Dictionary where Key == String, Value == Any? {

    func mutableCopy() -> NSMutableDictionary {
        // swiftlint:disable:next force_cast
        return (self as NSDictionary).mutableCopy() as! NSMutableDictionary
    }
}

internal extension NSMutableDictionary {

    func updateValue(_ value: Value?, forKey key: String) {
        setObject(value as Any, forKey: key as NSString)
    }

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
