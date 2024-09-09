//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension ScalarContainer {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
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
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let scalarContainer = ScalarContainer.keys

    model.pluralName = "ScalarContainers"

    model.attributes(
      .primaryKey(fields: [scalarContainer.id])
    )

    model.fields(
      .field(scalarContainer.id, is: .required, ofType: .string),
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
      .field(scalarContainer.myIPAddress, is: .optional, ofType: .string),
      .field(scalarContainer.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(scalarContainer.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<ScalarContainer> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension ScalarContainer: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == ScalarContainer {
  var id: FieldPath<String>   {
      string("id")
    }
  var myString: FieldPath<String>   {
      string("myString")
    }
  var myInt: FieldPath<Int>   {
      int("myInt")
    }
  var myDouble: FieldPath<Double>   {
      double("myDouble")
    }
  var myBool: FieldPath<Bool>   {
      bool("myBool")
    }
  var myDate: FieldPath<Temporal.Date>   {
      date("myDate")
    }
  var myTime: FieldPath<Temporal.Time>   {
      time("myTime")
    }
  var myDateTime: FieldPath<Temporal.DateTime>   {
      datetime("myDateTime")
    }
  var myTimeStamp: FieldPath<Int>   {
      int("myTimeStamp")
    }
  var myEmail: FieldPath<String>   {
      string("myEmail")
    }
  var myJSON: FieldPath<String>   {
      string("myJSON")
    }
  var myPhone: FieldPath<String>   {
      string("myPhone")
    }
  var myURL: FieldPath<String>   {
      string("myURL")
    }
  var myIPAddress: FieldPath<String>   {
      string("myIPAddress")
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
