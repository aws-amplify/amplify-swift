//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

extension Model {

    internal func sqlValues(for fields: [ModelField]?) -> [Binding?] {
        let modelType = type(of: self)
        let modelFields = fields ?? modelType.schema.allFields
        let values: [Binding?] = modelFields.map { field in
            let value = self[field.name]

            if value == nil {
                return nil
            }

            if let value = value as? Date {
                return value.datatypeValue
            }

            if let value = value as? Bool {
                return value.datatypeValue
            }

            // if value is a connected model, get its primary key
            if let value = value as? Model, field.isForeignKey {
                let connectedModel: Model.Type = type(of: value)
                return value[connectedModel.schema.primaryKey.name] as? String
            }

            // if value conforms to binding, resolve it
            if let value = value as? Binding {
                return value
            }

            // TODO fallback, should revisit this strategy
            return nil
        }
        return values
    }

}

extension Array where Element == Model.Type {

    /// Sort the [PersistentModel.Type] array based on the dependencies between them.
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

        func walkConnectedModels(of modelType: Model.Type) {
            if !sortedKeys.contains(modelType.schema.name) {
                let connectedModels = modelType.schema.allFields
                    .filter { $0.isForeignKey }
                    .map { $0.connectedModel! }
                connectedModels.forEach(walkConnectedModels(of:))

                let key = modelType.schema.name
                sortedKeys.append(key)
                sortMap[key] = modelType
            }
        }
        forEach(walkConnectedModels(of:))
        return sortedKeys.map { sortMap[$0]! }
    }

}
