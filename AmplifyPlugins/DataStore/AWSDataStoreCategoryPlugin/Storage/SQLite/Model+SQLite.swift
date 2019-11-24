//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// Extended types that conform to `Persistable` in order to provide conversion to SQLite's `Binding`
/// types. This is necessary so `Model` properties' map values to a SQLite compatible types.
extension Persistable {

    /// Convert the internal `Persistable` type to a `Binding` compatible value.
    ///
    /// Most often the types will be interchangeable. However, in some cases a custom
    /// conversion might be necessary.
    ///
    /// - Note: a `preconditionFailure` might happen in case the value cannot be converted.
    ///
    /// - Returns: the value as `Binding`
    internal func asBinding() -> Binding {
        let value = self

        if let value = value as? Bool {
            return Int(value.datatypeValue)
        }

        // if value conforms to binding, resolve it
        if let value = value as? Binding {
            return value
        }

        if let value = value as? Date {
            return value.datatypeValue
        }

        preconditionFailure("""
        Value \(String(describing: value)) of type \(String(describing: type(of: value)))
        is not a SQLite Binding compatible type.
        """)
    }
}

extension Model {

    /// Get the values of a `Model` for the fields relevant to a SQL query. The order of the
    /// values follow the same order of the model's columns.
    ///
    /// Use the `fields` parameter to convert just a subset of fields.
    ///
    /// - Parameter fields: an optional subset of fields
    /// - Returns: an array of SQLite's `Binding` compatible type
    internal func sqlValues(for fields: [ModelField]?) -> [Binding?] {
        let modelType = type(of: self)
        let modelFields = fields ?? modelType.schema.sortedFields
        let values: [Binding?] = modelFields.map { field in
            let value = self[field.name]
            // TODO why are `nil` optional number types not being skipped as expected?
            if value == nil {
                return nil
            }
            // if value is an associated model, get its id
            if let value = value as? Model, field.isForeignKey {
                let associatedModel: Model.Type = type(of: value)
                return value[associatedModel.schema.primaryKey.name] as? String
            } else if let value = value as? Persistable {
                return value.asBinding()
            } else {
                return nil
//                preconditionFailure("""
//                Type \(String(describing: type(of: value))) from \(modelType) field
//                \(field.name) is not a compatible type. Refer to types that conform to Persistable.
//                """)
            }
        }
        return values
    }

}

extension Array where Element == Model.Type {

    /// Sort the [Model.Type] array based on the associations between them.
    ///
    /// The order the tables are created for each model depends on their relationships.
    /// The tables for the models that own the `foreign key` of the relationship can only
    /// be created *after* the other edge of the relationship is created.
    ///
    /// For example:
    ///
    /// ```
    /// Blog (1) - (n) Post (1) - (n) Comment
    /// ```
    /// The `Comment` table can only be created after the `Post`, which can only be
    /// created after `Blog`. Therefore:
    ///
    /// ```
    /// let models = [Comment.self, Post.self, Blog.self]
    /// models.sortedByDependencyOrder() == [Blog.self, Post.self, Comment.self]
    /// ```
    func sortByDependencyOrder() -> Self {
        var sortedKeys: [String] = []
        var sortMap: [String: Model.Type] = [:]

        func walkAssociatedModels(of modelType: Model.Type) {
            if !sortedKeys.contains(modelType.schema.name) {
                let associatedModels = modelType.schema.sortedFields
                    .filter { $0.isForeignKey }
                    .map { $0.requiredAssociatedModel }
                associatedModels.forEach(walkAssociatedModels(of:))

                let key = modelType.schema.name
                sortedKeys.append(key)
                sortMap[key] = modelType
            }
        }
        forEach(walkAssociatedModels(of:))
        return sortedKeys.map { sortMap[$0]! }
    }

}
