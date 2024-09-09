//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension MyCustomModel8 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case desc
    case children
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let myCustomModel8 = MyCustomModel8.keys

    model.pluralName = "MyCustomModel8s"

    model.fields(
      .id(),
      .field(myCustomModel8.name, is: .required, ofType: .string),
      .field(myCustomModel8.desc, is: .optional, ofType: .string),
      .field(myCustomModel8.children, is: .optional, ofType: .embeddedCollection(of: MyNestedModel8.self))
    )
    }
}
