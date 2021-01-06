//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias SelectionSet = Tree<SelectionSetField>

public enum SelectionSetFieldType {
    case pagination
    case model
    case embedded
    case value
}

public class SelectionSetField {
    var name: String?
    var fieldType: SelectionSetFieldType
    public init(name: String? = nil, fieldType: SelectionSetFieldType) {
        self.name = name
        self.fieldType = fieldType
    }
}

extension SelectionSet {

    /// Construct a `SelectionSet` with model fields
    convenience init(fields: [ModelField]) {
        self.init(value: SelectionSetField(fieldType: .model))
        withModelFields(fields)
    }

    func withModelFields(_ fields: [ModelField]) {
        fields.forEach { field in
            if field.isEmbeddedType, let embeddedTypeSchema = field.embeddedTypeSchema {
                let child = SelectionSet(value: .init(name: field.name, fieldType: .embedded))
                child.withEmbeddableFields(embeddedTypeSchema.sortedFields)
                self.addChild(settingParentOf: child)
            } else if field.isAssociationOwner,
                let associatedModelName = field.associatedModelName,
                let schema = ModelRegistry.modelSchema(from: associatedModelName) {
                let child = SelectionSet(value: .init(name: field.name, fieldType: .model))
                child.withModelFields(schema.graphQLFields)
                self.addChild(settingParentOf: child)
            } else {
                self.addChild(settingParentOf: .init(value: .init(name: field.graphQLName, fieldType: .value)))
            }
        }

        addChild(settingParentOf: .init(value: .init(name: "__typename", fieldType: .value)))
    }

    func withEmbeddableFields(_ fields: [ModelField]) {
        fields.forEach { field in
            if field.isEmbeddedType, let embeddedTypeSchema = field.embeddedTypeSchema {
                let child = SelectionSet(value: .init(name: field.name, fieldType: .embedded))
                child.withEmbeddableFields(embeddedTypeSchema.sortedFields)
                self.addChild(settingParentOf: child)
            } else {
                self.addChild(settingParentOf: .init(value: .init(name: field.name, fieldType: .value)))
            }
        }
        addChild(settingParentOf: .init(value: .init(name: "__typename", fieldType: .value)))
    }

    /// Generate the string value of the `SelectionSet` used in the GraphQL query document
    ///
    /// This method operates on `SelectionSet` with the root node containing a nil `value.name` and expects all inner
    /// nodes to contain a value. It will generate a string with a nested and indented structure like:
    /// ```
    /// items {
    ///   foo
    ///   bar
    ///   modelName {
    ///     foo
    ///     bar
    ///   }
    /// }
    /// nextToken
    /// startAt
    /// ```
    func stringValue(indentSize: Int = 0) -> String {
        var result = [String]()
        let indent = indentSize == 0 ? "" : String(repeating: "  ", count: indentSize)

        switch value.fieldType {
        case .model, .pagination, .embedded:
            if let name = value.name {
                result.append(indent + name + " {")
                children.forEach { innerSelectionSetField in
                    result.append(innerSelectionSetField.stringValue(indentSize: indentSize + 1))
                }
                result.append(indent + "}")
            } else {
                children.forEach { innerSelectionSetField in
                    result.append(innerSelectionSetField.stringValue(indentSize: indentSize))
                }
            }
        case .value:
            guard let name = value.name else {
                return ""
            }
            result.append(indent + name)
        }

        return result.joined(separator: "\n    ")
    }
}
