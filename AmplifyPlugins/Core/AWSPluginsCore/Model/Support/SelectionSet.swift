//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias SelectionSet = TreeNode<SelectionSetField>

public class TreeNode<E> {
    var value: E
    var children: [TreeNode<E>] = []
    weak var parent: TreeNode<E>?

    init(value: E) {
        self.value = value
    }

    func add(child: TreeNode) {
        children.append(child)
        child.parent = self
    }
}

public enum SelectionSetFieldType {
    case pagination
    case model
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
            let isRequiredAssociation = field.isRequired && field.isAssociationOwner
            if isRequiredAssociation, let associatedModel = field.associatedModel {
                let child = SelectionSet(value: .init(name: field.name, fieldType: .model))
                child.withModelFields(associatedModel.schema.graphQLFields)
                self.add(child: child)
            } else {
                self.add(child: .init(value: .init(name: field.graphQLName, fieldType: .value)))
            }
        }

        add(child: .init(value: .init(name: "__typename", fieldType: .value)))
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

        // Account for the root node,
        if let name = value.name {
            result.append(indent + name)
        }

        children.forEach { selectionSetField in
            guard let name = selectionSetField.value.name else {
                return
            }

            if !selectionSetField.children.isEmpty {
                result.append(indent + name + " {")
                selectionSetField.children.forEach { innerSelectionSetField in
                    result.append(innerSelectionSetField.stringValue(indentSize: indentSize + 1))
                }
                result.append(indent + "}")
            } else {
                result.append(indent + name)
            }
        }

        return result.joined(separator: "\n    ")
    }
}
