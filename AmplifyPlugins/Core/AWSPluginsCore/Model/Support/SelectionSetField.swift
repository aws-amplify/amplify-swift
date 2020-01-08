//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class SelectionSetField {
    var value: String
    var innerFields: [SelectionSetField]

    public init(value: String, innerFields: [SelectionSetField] = [SelectionSetField]()) {
        self.value = value
        self.innerFields = innerFields
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
