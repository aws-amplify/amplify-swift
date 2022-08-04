//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension ScalarContainer {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case myString
    case myInt
    case myDouble
    case myBool
    case myDate
    case myTime
    case myDateTime
    case myTimeStamp
    case myEmail
    case myJSON
    case myPhone
    case myURL
    case myIPAddress
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let scalarContainer = ScalarContainer.keys

    model.listPluralName = "ScalarContainers"
    model.syncPluralName = "ScalarContainers"

    model.fields(
      .id(),
      .field(scalarContainer.myString, is: .optional, ofType: .string),
      .field(scalarContainer.myInt, is: .optional, ofType: .int),
      .field(scalarContainer.myDouble, is: .optional, ofType: .double),
      .field(scalarContainer.myBool, is: .optional, ofType: .bool),
      .field(scalarContainer.myDate, is: .optional, ofType: .date),
      .field(scalarContainer.myTime, is: .optional, ofType: .time),
      .field(scalarContainer.myDateTime, is: .optional, ofType: .dateTime),
      .field(scalarContainer.myTimeStamp, is: .optional, ofType: .int),
      .field(scalarContainer.myEmail, is: .optional, ofType: .string),
      .field(scalarContainer.myJSON, is: .optional, ofType: .string),
      .field(scalarContainer.myPhone, is: .optional, ofType: .string),
      .field(scalarContainer.myURL, is: .optional, ofType: .string),
      .field(scalarContainer.myIPAddress, is: .optional, ofType: .string)
    )
    }
}
