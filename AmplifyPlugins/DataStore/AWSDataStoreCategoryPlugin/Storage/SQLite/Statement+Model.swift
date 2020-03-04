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
    /// - Parameter modelType the target `Model` type
    /// - Returns: an array of `Model` of the specified type
    func convert<M: Model>(to modelType: M.Type) throws -> [M]

}

/// Extend `Statement` with the model conversion capabilities defined by `StatementModelConvertible`.
extension Statement: StatementModelConvertible {

    var logger: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.dataStore.displayName)
    }

    public func convert<M: Model>(to modelType: M.Type) throws -> [M] {
        var rows: [ModelValues] = []
        var convertedCache: ConvertCache = [:]
        for row in self {
            let modelDictionary = try mapEach(row: row,
                                              to: modelType,
                                              cache: &convertedCache)
            rows.append(modelDictionary)
        }
        let values: ModelValues = ["elements": rows]
        let result: StatementResult<M> = try StatementResult.from(dictionary: values)
        return result.elements
    }

    internal func mapEach(row: Element,
                          to modelType: Model.Type,
                          cache: inout ConvertCache,
                          fieldName: String? = nil) throws -> ModelValues {
        // hold the extracted values
        var values: ModelValues = [:]

        let columns = columnNames
        let propertyPrefix = fieldName != nil ? "\(fieldName!)." : nil
        let schema = modelType.schema

        // check if model with the given id was already converted to ModelValues
        // this is a needed optimization since the same row can be present in different
        // parts of the result set, including in circular association scenarios
        let keyName = (propertyPrefix ?? "") + schema.primaryKey.sqlName
        let indexOfId = columns.firstIndex(of: keyName)
        if let index = indexOfId, let id = row[index] as? String, let cached = cache[id] {
            return cached
        }

        for (index, column) in columns.enumerated()
            where propertyPrefix == nil || column.starts(with: propertyPrefix!) {

            let name: String = propertyPrefix != nil
                ? column.replacingOccurrences(of: propertyPrefix!, with: "")
                : column
            if name.firstIndex(of: ".") != nil {
                let propertyName = String(name.split(separator: ".").first!)
                guard let associatedField = schema.field(withName: propertyName) else {
                    preconditionFailure("""
                    Field `\(propertyName)` not found on `\(schema.name)`.
                    The property was found on the result set but was not defined in the
                    `\(schema.name)` schema.
                    """)
                }
                let associatedModelType = associatedField.requiredAssociatedModel
                let associatedModel = try mapEach(row: row,
                                                  to: associatedModelType,
                                                  cache: &cache,
                                                  fieldName: propertyName)
                values[propertyName] = associatedModel
            } else if let field = schema.field(withName: name) {
                values[name] = try SQLiteModelValueConverter.convertToSource(from: row[index],
                                                                             fieldType: field.type)
            } else {
                logger.debug("""
                A column named \(name) was found in the result set but no field on
                \(schema.name) could be found with that name and it will be ignored.
                """)
            }
        }

        if let id = values[schema.primaryKey.name] as? String {
            // create instances of lazy-load lists of fields that represent "many" associations
            schema.fields.values.filter { $0.isArray }.forEach { field in
                // TODO extract this to a List utility
                let lazyListDecodable: [String: Any?] = [
                    "associatedId": id,
                    "associatedField": field.associatedField?.name,
                    "elements": []
                ]
                values[field.name] = lazyListDecodable
            }
            cache.updateValue(values, forKey: id)
        }
        return values
    }

}
