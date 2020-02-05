//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Contains detail about the current selection set. `pagination` indicates that it contains paginated fields.
/// `modelField` indicates that the values represent the property names from a `ModelSchema`.
public enum SelectionSetType {
    case pagination
    case modelField
}

/// A nested structure to contain a list of `SelectionSetField`, each of which may optionally contain another
/// `SelectionSet`
public struct SelectionSet {
    var fields: [SelectionSetField]
    var type: SelectionSetType

    public init(fields: [SelectionSetField], type: SelectionSetType) {
        self.fields = fields
        self.type = type
    }

    mutating func append(_ selectionSetField: SelectionSetField) {
        fields.append(selectionSetField)
    }

    mutating func update(_ field: SelectionSetField, at index: Int) {
        fields[index] = field
    }
}

public struct SelectionSetField {
    public var value: String
    public var innerSelectionSet: SelectionSet?

    public init(value: String, innerSelectionSet: SelectionSet? = nil) {
        self.value = value
        self.innerSelectionSet = innerSelectionSet
    }

    mutating func updateInnerSelectionSet(_ innerSelectionSet: SelectionSet) {
        self.innerSelectionSet = innerSelectionSet
    }

    public func toString(indentSize: Int = 0) -> String {
        var result = [String]()
        let indent = indentSize == 0 ? "" : String(repeating: "  ", count: indentSize)

        if let innerSelectionSet = innerSelectionSet, !innerSelectionSet.fields.isEmpty {
            result.append(indent + value + " {")
            innerSelectionSet.fields.forEach { field in
                result.append(field.toString(indentSize: indentSize + 1))
            }
            result.append(indent + "}")
        } else {
            result.append(indent + value)
        }
        return result.joined(separator: "\n    ")
    }
}

/// Extension to apply pagination and conflict resolution fields onto a selection set, specific to the observed
/// Amplify transformation logic.
extension SelectionSet {

    /// Wrap the selection set in `items` and append a `nextToken` to the end
    var paginated: SelectionSet {
        SelectionSet(
            fields: [SelectionSetField(value: "items", innerSelectionSet: self), SelectionSetField(value: "nextToken")],
            type: .pagination)
    }

    /// Apply `startedAt` for paginated selection sets and `_version`, `_deleted`, `_lastChangedAt` fields onto model
    /// related fields
    var withConflictResolution: SelectionSet {
        var selectionSet = self
        switch type {
        case .pagination:
            // append `startedAt` for paginated selection sets, then extract the wrapped selection set from the first
            // field, which will correlate to the "items" selection set field, then recursively apply
            // `withConflictResolution`
            selectionSet.append(SelectionSetField(value: "startedAt"))
            if var first = selectionSet.fields.first, let innerSelectionSet = first.innerSelectionSet {
                first.innerSelectionSet = innerSelectionSet.withConflictResolution
                selectionSet.fields[0] = first
            }
        case .modelField:
            // append related conflict resolution fields to the end of the list of selection set fields
            selectionSet.append(SelectionSetField(value: "_version"))
            selectionSet.append(SelectionSetField(value: "_deleted"))
            selectionSet.append(SelectionSetField(value: "_lastChangedAt"))

            // For each selection set in each selection set field, recursively apply conflict resolution fields
            for (index, field) in selectionSet.fields.enumerated() {
                var newField = field
                if let innerSelectionSet = field.innerSelectionSet {
                    newField.updateInnerSelectionSet(innerSelectionSet.withConflictResolution)
                    selectionSet.update(newField, at: index)
                }
            }
        }

        return selectionSet
    }
}
