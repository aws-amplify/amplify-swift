//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct SelectionSetField {
    public var value: String
    public var innerFields: [SelectionSetField]

    public init(value: String, innerFields: [SelectionSetField] = [SelectionSetField]()) {
        self.value = value
        self.innerFields = innerFields
    }

    mutating func updateInnerFields(_ fields: [SelectionSetField]) {
        innerFields = fields
    }

    public func toString(indentSize: Int = 0) -> String {
        var result = [String]()
        let indent = indentSize == 0 ? "" : String(repeating: "  ", count: indentSize)

        if !innerFields.isEmpty {
            result.append(indent + value + " {")
            innerFields.forEach { field in
                result.append(field.toString(indentSize: indentSize + 1))
            }
            result.append(indent + "}")
        } else {
            result.append(indent + value)
        }
        return result.joined(separator: "\n    ")
    }
}

// Provide the Amplify specific way to paginate and to sync enabled
extension Array where Element == SelectionSetField {
    var paginated: [SelectionSetField] {
        [SelectionSetField(value: "items", innerFields: self), SelectionSetField(value: "nextToken")]
    }

    var syncEnabled: [SelectionSetField] {
        appendSyncFields(self)
    }

    func appendSyncFields(_ fields: [SelectionSetField]) -> [SelectionSetField] {
        var fields = fields
        fields.append(SelectionSetField(value: "_version"))
        fields.append(SelectionSetField(value: "_deleted"))
        fields.append(SelectionSetField(value: "_lastChangedAt"))

        for (index, field) in fields.enumerated() {
            var newField = field
            if !field.innerFields.isEmpty {
                newField.updateInnerFields(appendSyncFields(field.innerFields))
                fields[index] = newField
            }
        }

        return fields
    }
}
