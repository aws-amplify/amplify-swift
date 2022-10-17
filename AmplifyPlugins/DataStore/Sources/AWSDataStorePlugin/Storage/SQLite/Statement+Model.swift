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
                           using statement: SelectStatement,
                           eagerLoad: Bool) throws -> [M]

}

/// Extend `Statement` with the model conversion capabilities defined by `StatementModelConvertible`.
extension Statement: StatementModelConvertible {

    var logger: Logger {
        Amplify.Logging.logger(forCategory: .dataStore)
    }

    
    func convert<M: Model>(to modelType: M.Type,
                           withSchema modelSchema: ModelSchema,
                           using statement: SelectStatement,
                           eagerLoad: Bool = true) throws -> [M] {
        let elements: [ModelValues] = try self.convertToModelValues(to: modelType,
                                                                    withSchema: modelSchema,
                                                                    using: statement,
                                                                    eagerLoad: eagerLoad)
        let values: ModelValues = ["elements": elements]
        let result: StatementResult<M> = try StatementResult.from(dictionary: values)
        return result.elements
    }
    
    func convertToModelValues<M: Model>(to modelType: M.Type,
                                        withSchema modelSchema: ModelSchema,
                                        using statement: SelectStatement,
                                        eagerLoad: Bool = true) throws -> [ModelValues] {
        var elements: [ModelValues] = []

        // parse each row of the result
        let iter = makeIterator()
        while let row = try iter.failableNext() {
            let modelDictionary = try convert(row: row, withSchema: modelSchema, using: statement, eagerLoad: eagerLoad)
            elements.append(modelDictionary)
        }
        return elements
    }
    
    func convert(row: Element,
                 withSchema modelSchema: ModelSchema,
                 using statement: SelectStatement,
                 eagerLoad: Bool = true) throws -> ModelValues {
        let columnMapping = statement.metadata.columnMapping
        let modelDictionary = ([:] as ModelValues).mutableCopy()
        var skipColumns = Set<String>()
        var foreignKeyValues = [(String, Binding?)]()
        for (index, value) in row.enumerated() {
            let column = columnNames[index]
            guard let (schema, field) = columnMapping[column] else {
                logger.debug("[LazyLoad] Foreign key `\(column)` was found in the SQL result set with value: \(value)")
                foreignKeyValues.append((column, value))
                continue
            }
            
            let modelValue = try SQLiteModelValueConverter.convertToSource(
                from: value,
                fieldType: field.type
            )

            // Check if the value for the primary key is `nil`. This is when an associated model does not exist.
            // To create a decodable `modelDictionary` that can be decoded to the Model types, the entire
            // object at this particular key should be set to `nil`. The following code does that by dropping the last
            // path from the column, for example given "blog.id" `column` has a nil `modelValue`, then store the
            // keypath in `skipColumns`, which will be used to set modelDictionary["blog"] to nil later on.
            //
            // `skipColumns` keeps track of these scenarios. At this point in the code we cannot make an assumption
            // about the ordering of the columns, it may handle "blog.description", then "blog.id", then "blog.title".
            // The code will perform the following:
            //  1. set ["blog"]["description"] = `nil`, because it has not encountered `nil` primary key
            //  2. store skipColumn["blog"], because the value is the primary key and is nil
            //  3. skip setting modelDictionary["blog"]["title"], because `skipColumn` has been set for "blog".
            if field.isPrimaryKey && modelValue == nil {
                let keyPathParent = column.dropLastPath()
                skipColumns.insert(keyPathParent)
            }

            if skipColumns.isEmpty {
                modelDictionary.updateValue(modelValue, forKeyPath: column)
            } else {
                let keyPathParent = column.dropLastPath()
                if !skipColumns.contains(keyPathParent) {
                    modelDictionary.updateValue(modelValue, forKeyPath: column)
                }
            }

            // create lazy list for "many" relationships
            // this code only executes once when the `id` is the primary key of the current model
            // and runs in an iteration over all of the associations
            // For example, when the value is the `id` of the Blog, then the field.isPrimaryKey is satisfied.
            // Every association of the Blog, such as the has-many Post is populated with the List with
            // associatedId == blog's id. This way, the list of post can be lazily loaded later using the associated id.
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

        // the `skipColumns` is sorted from longest to shortest since we eager load all belongs-to, for the example of
        // a Comment, that belongs to a Post, that belongs to a Blog. Comment has nil Post and nil Blog. The
        // `skipColumns` will be populated as
        //  - skipColumns["post"]
        //  - skipColumns["post.blog"]
        //
        // By ordering it as "post.blog" then "post", before setting the `nil` values for those keypaths, then the
        // shortest keypath will the last key in the `modelDictionary`. modelDictionary["post"]["blog"] will be
        // replaced with modelDictionary["post"] = nil.
        //
        // If there does exist a post but no blog on the post, then the following `skipColumns` would be populated:
        //  - skipColumns["post.blog"] (since only primary key for blog does not exist, post object exists)
        // and the resulting modelDictionary will be populated:
        // modelDictionary["post"]["id"] = <ID>
        // modelDictionary["post"][<remaining required/optional fields of post>] = <values>
        // modelDictionary["post"]["blog"] = nil
        let sortedColumns = skipColumns.sorted(by: { $0.count > $1.count })
        for skipColumn in sortedColumns {
            modelDictionary.updateValue(nil, forKeyPath: skipColumn)
        }
        modelDictionary["__typename"] = modelSchema.name

        // `foreignKeyValues` are all foreign keys and their values that can be added to the object for lazy loading
        // belongs to associations. 
        if !eagerLoad {
            for foreignKeyValue in foreignKeyValues {
                let foreignColumnName = foreignKeyValue.0
                if let foreignModelField = modelSchema.foreignKeys.first(where: { modelField in
                    modelField.sqlName == foreignColumnName
                }) {
                    modelDictionary[foreignModelField.name] = ["identifier": foreignKeyValue.1]
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

extension String {
    /// Utility to return the second last keypath (if available) given a keypath. For example,
    ///
    /// - "post" returns the key path root "post"
    /// - "post.id" returns "post", dropping the path "id"
    /// - "post.blog.id" returns "post.blog", dropping the path "id"
    ///
    /// - Parameter keyPath: the key path as a `String` (e.g. "nested.key")
    func dropLastPath() -> String {
        if firstIndex(of: ".") == nil {
            return self
        }

        let keyComponents = components(separatedBy: ".")
        let index = keyComponents.count - 2
        if index == 0 {
            return keyComponents[index]
        } else {
            let subKeyComponents = keyComponents.dropLast()
            return subKeyComponents.joined(separator: ".")
        }
    }
}
