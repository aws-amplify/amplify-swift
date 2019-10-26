//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

typealias ModelValues = [String: Any]

/// Struct used to hold the values extracted from a executed `Statement`.
///
/// This type allows the results to be decoded into the actual models with a single call
/// instead of decoding each row individually. This keeps serialization of
/// large result sets efficient.
struct StatementResult<M: Model>: Decodable {

    let models: [M]

    public static func from(dictionary: ModelValues) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try JSONDecoder().decode(Self.self, from: data)
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

    public func convert<M: Model>(to modelType: M.Type) throws -> [M] {
        var rows: [ModelValues] = []
        for row in self {
            let modelDictionary = try mapEach(row: row, to: modelType)
            rows.append(modelDictionary)
        }
        let values: ModelValues = ["models": rows]
        let result: StatementResult<M> = try StatementResult.from(dictionary: values)
        return result.models
    }

    internal func mapEach(row: Element,
                          to modelType: Model.Type,
                          fieldName: String? = nil) throws -> ModelValues {
        // hold the extracted values
        var values: ModelValues = [:]

        let columns = columnNames
        let propertyPrefix = fieldName != nil ? "\(fieldName!)." : nil
        let schema = modelType.schema

        for (index, column) in columns.enumerated()
            where propertyPrefix == nil || column.starts(with: propertyPrefix!) {

            let name: String = propertyPrefix != nil
                ? column.replacingOccurrences(of: propertyPrefix!, with: "")
                : column
            if name.firstIndex(of: ".") != nil {
                let propertyName = String(name.split(separator: ".").first!)
                guard let connectedField = schema.field(withName: propertyName) else {
                    preconditionFailure("""
                    Field `\(propertyName)` not found on `\(schema.name)`.
                    The property was found on the result set but was not defined in the
                    `\(schema.name)` schema.
                    """)
                }
                guard let connectedModelType = connectedField.connectedModel else {
                    preconditionFailure("""
                    Property `\(propertyName)` must have a valid associated Model.
                    Make sure your properties that represent relationship between two model
                    must be properly annotated with `.connected`.
                    """)
                }
                let connectedModel = try mapEach(row: row,
                                                 to: connectedModelType,
                                                 fieldName: propertyName)
                values[propertyName] = connectedModel
            } else if let field = schema.field(withName: name) {
                values[name] = field.value(from: row[index])
            } else {
                // TODO log ignored column
            }
        }
        return values
    }

}
