//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension CustomerOrder {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case orderId
    case email
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let customerOrder = CustomerOrder.keys

    model.listPluralName = "CustomerOrders"
    model.syncPluralName = "CustomerOrders"
    model.attributes(.index(fields: ["orderId", "id"], name: nil))
    model.fields(
      .id(),
      .field(customerOrder.orderId, is: .required, ofType: .string),
      .field(customerOrder.email, is: .required, ofType: .string)
    )
    }
}
