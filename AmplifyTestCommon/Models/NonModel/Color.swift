//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Color: Embeddable {
  var name: String
  var red: Int
  var green: Int
  var blue: Int
}

extension Color {
    public enum CodingKeys: CodingKey {
        case name
        case red
        case green
        case blue
    }

    public static let keys = CodingKeys.self

    public static let schema = defineSchema { embedded in
        let color = Color.keys
        embedded.fields(.field(color.name, is: .required, ofType: .string),
                       .field(color.red, is: .required, ofType: .int),
                       .field(color.green, is: .required, ofType: .int),
                       .field(color.blue, is: .required, ofType: .int))
    }
}
