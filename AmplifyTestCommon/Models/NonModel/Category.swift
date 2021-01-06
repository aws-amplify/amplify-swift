//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Category: Embeddable {
  var name: String
  var color: Color
}

extension Category {

    public enum CodingKeys: CodingKey {
        case name
        case color
    }

    public static let keys = CodingKeys.self

    public static let schema = defineSchema { embedded in
        let category = Category.keys
        embedded.fields(.field(category.name, is: .required, ofType: .string),
                       .field(category.color, is: .required, ofType: .embedded(type: Color.self)))
    }
}
