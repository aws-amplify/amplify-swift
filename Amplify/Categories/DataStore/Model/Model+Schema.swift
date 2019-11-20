//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Model {

    public static var schema: ModelSchema {
        // TODO load schema from JSON when this it not overridden by specific models
        ModelSchema(name: modelName, fields: [:])
    }

    public var schema: ModelSchema {
        type(of: self).schema
    }

    /// Utility function that enables a DSL-like `ModelSchema` definition. Instead of building
    /// objects individually, developers can use this to create the schema with a more fluid
    /// programming model.
    ///
    /// - Example:
    /// ```swift
    /// static let schema = defineSchema { model in
    ///     model.fields(
    ///         .field(name: "title", is: .required, ofType: .string)
    ///     )
    /// }
    /// ```
    ///
    /// - Parameters
    ///   - name: the name of the Model. Defaults to the class name
    ///   - attributes: model attributes (aka "directives" or "annotations")
    ///   - define: the closure used to define the model attributes and fields
    /// - Returns: a valid `ModelSchema` instance
    public static func defineSchema(name: String? = nil,
                                    attributes: ModelAttribute...,
                                    define: (inout ModelSchemaDefinition) -> Void) -> ModelSchema {
        var definition = ModelSchemaDefinition(name: name ?? modelName,
                                               attributes: attributes)
        define(&definition)
        return definition.build()
    }
}
