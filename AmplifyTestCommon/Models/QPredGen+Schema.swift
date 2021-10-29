//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension QPredGen {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case myBool
    case myDouble
    case myInt
    case myString
    case myDate
    case myDateTime
    case myTime
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let qPredGen = QPredGen.keys

    model.listPluralName = "QPredGens"
    model.syncPluralName = "QPredGens"

    model.fields(
      .id(),
      .field(qPredGen.name, is: .required, ofType: .string),
      .field(qPredGen.myBool, is: .optional, ofType: .bool),
      .field(qPredGen.myDouble, is: .optional, ofType: .double),
      .field(qPredGen.myInt, is: .optional, ofType: .int),
      .field(qPredGen.myString, is: .optional, ofType: .string),
      .field(qPredGen.myDate, is: .optional, ofType: .date),
      .field(qPredGen.myDateTime, is: .optional, ofType: .dateTime),
      .field(qPredGen.myTime, is: .optional, ofType: .time)
    )
    }
}
