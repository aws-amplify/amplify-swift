//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

protocol SQLProperty {
    func value(from value: Binding?) -> Any?
}

protocol SQLPropertyMetadata {
    var sqlName: String { get }
    var sqlType: SQLDataType { get }
    var isForeignKey: Bool { get }
}

enum SQLDataType: String {
    case text
    case integer
    case real
}

extension String {
    public func quoted() -> String {
        return "\"\(self)\""
    }
}

extension PropertyMetadata: SQLPropertyMetadata {
    var sqlName: String {
        return isForeignKey ? name + "Id" : name
    }

    var sqlType: SQLDataType {
        switch type {
        case .string, .enum, .date, .model:
            return .text
        case .int, .boolean:
            return .integer
        case .decimal:
            return .real
        default:
            return .text
        }
    }

    var isForeignKey: Bool {
        guard isConnected else {
            return false
        }
        switch type {
        case .model:
            return true
        default:
            return false
        }
    }

    func columnName(forNamespace namespace: String? = nil) -> String {
        var column = sqlName.quoted()
        if let namespace = namespace {
            column = namespace.quoted() + "." + column
        }
        return column
    }

    func columnAlias(forNamespace namespace: String? = nil) -> String {
        var column = sqlName
        if let namespace = namespace {
            column = "\(namespace).\(column)"
        }
        return "as \(column.quoted())"
    }

}

extension ModelProperty {
    func value(from value: Binding?) -> Any? {
        // TODO improve this with better Model <-> DB Result serialization solution
        switch metadata.type {
        case .boolean:
            if let value = value as? Int64 {
                return Bool.fromDatatypeValue(value)
            }
        case .date:
            if let value = value as? String {
                // The decoder translates Double to Date
                return Date.fromDatatypeValue(value).timeIntervalSince1970
            }
        case .collection:
            return value ?? []
        default:
            return value
        }
        return value
    }
}

extension Array where Element == ModelProperty {

    func foreignKeys() -> [ModelProperty] {
        return filter { $0.metadata.isForeignKey }
    }

    func columns() -> [ModelProperty] {
        return filter { !$0.metadata.isConnected || $0.metadata.isForeignKey }
    }

    func by(name: String) -> ModelProperty? {
        return first { $0.metadata.name == name }
    }

}

extension Model where Self: ModelMetadata {

    internal func sqlValues(for properties: ModelProperties?) -> [Binding?] {
        let model = type(of: self)
        let modelProperties = properties != nil ? properties! : model.properties
        let propertiesValues: [Binding?] = modelProperties.map { prop in
            let value = self[prop.metadata.key]

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
            if let value = value as? Model, prop.metadata.isForeignKey {
                let connectedModel: Model.Type = type(of: value)

                // TODO improve this
                return value[connectedModel.primaryKey.metadata.name] as? String
            }

            // if value conforms to binding, resolve it
            if let value = value as? Binding {
                return value
            }

            // TODO fallback, should revisit this strategy
            return nil
        }
        return propertiesValues
    }

}

extension Array where Element == PersistentModel.Type {

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
        var sortMap: [String: PersistentModel.Type] = [:]

        func walkConnectedModels(of modelType: PersistentModel.Type) {
            if !sortedKeys.contains(modelType.name) {
                let connectedModels = modelType.properties
                    .filter { $0.metadata.isForeignKey }
                    .map { $0.metadata.connectedModel! }
                connectedModels.forEach(walkConnectedModels(of:))

                let key = modelType.name
                sortedKeys.append(key)
                sortMap[key] = modelType
            }
        }
        forEach(walkConnectedModels(of:))
        return sortedKeys.map { sortMap[$0]! }
    }

}
