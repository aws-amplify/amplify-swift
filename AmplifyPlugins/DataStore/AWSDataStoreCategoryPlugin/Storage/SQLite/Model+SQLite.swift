//
// Copyright 2018-2020 Amazon.com,
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
        let valueType = type(of: value)
        do {
            let binding = try SQLiteModelValueConverter.convertToTarget(from: value,
                                                                        fieldType: .from(type: valueType))
            guard let validBinding = binding else {
                preconditionFailure("""
                Converting \(String(describing: value)) of type \(String(describing: valueType))
                to a SQLite Binding returned a nil value. This is likely a bug in the
                SQLiteModelValueConverter logic.
                """)
            }
            return validBinding
        } catch {
            preconditionFailure("""
            Value \(String(describing: value)) of type \(String(describing: valueType))
            is not a SQLite Binding compatible type. Error: \(error.localizedDescription)

            \(AmplifyErrorMessages.shouldNotHappenReportBugToAWS())
            """)
        }
    }
}

private let logger = Amplify.Logging.logger(forCategory: .dataStore)

extension Model {

    /// Get the values of a `Model` for the fields relevant to a SQL query. The order of the
    /// values follow the same order of the model's columns.
    ///
    /// Use the `fields` parameter to convert just a subset of fields.
    ///
    /// - Parameter fields: an optional subset of fields
    /// - Returns: an array of SQLite's `Binding` compatible type
    internal func sqlValues(for fields: [ModelField]? = nil) -> [Binding?] {
        let modelType = type(of: self)
        let modelFields = fields ?? modelType.schema.sortedFields
        let values: [Binding?] = modelFields.map { field in

            // self[field.name] subscript accessor returns an Any??, we need to do a few things:
            // - `guard` to make sure the field name exists on the model
            // - `guard` to ensure the returned value isn't nil
            // - Attempt to cast to Persistable to ensure the model value isn't incorrectly assigned to a type we
            //   can't handle
            guard let existingFieldValue = self[field.name] else {
                return nil
            }

            guard let anyValue = existingFieldValue else {
                return nil
            }

            // At this point, we have a value: Any. However, remember that Any could itself be an optional, so we're
            // not quite done yet.
            // swiftlint:disable syntactic_sugar
            let value: Any
            if case Optional<Any>.some(let unwrappedValue) = anyValue {
                value = unwrappedValue
            } else {
                return nil
            }
            // swiftlint:enable syntactic_sugar

            // Now `value` is still an Any, but we've assured ourselves that it's not an Optional, which means we can
            // safely attempt a cast to Persistable below.

            // if value is an associated model, get its id
            if let value = value as? Model, field.isForeignKey {
                let associatedModel: Model.Type = type(of: value)
                return value[associatedModel.schema.primaryKey.name] as? String
            }

            // otherwise, delegate to the value converter
            do {
                let binding = try SQLiteModelValueConverter.convertToTarget(from: value, fieldType: field.type)
                return binding
            } catch {
                logger.warn("""
                Error converting \(modelType.modelName).\(field.name) to the proper SQLite Binding.
                Root cause is: \(String(describing: error))
                """)
                return nil
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

        let sortedStartList = sorted { $0.modelName < $1.modelName }
        sortedStartList.forEach(walkAssociatedModels(of:))
        return sortedKeys.map { sortMap[$0]! }
    }

}
