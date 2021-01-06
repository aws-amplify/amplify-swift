//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation
/*
 Generated from:

 type QPredGen @model {
   id: ID!
   name: String!
   myBool: Boolean
   myDouble: Float
   myInt: Int
   myString: String
   myDate: AWSDate
   myDateTime: AWSDateTime
   myTime: AWSTime
 }
 */
public struct QPredGen: Model {
  public let id: String
  public var name: String
  public var myBool: Bool?
  public var myDouble: Double?
  public var myInt: Int?
  public var myString: String?
  public var myDate: Temporal.Date?
  public var myDateTime: Temporal.DateTime?
  public var myTime: Temporal.Time?

  public init(id: String = UUID().uuidString,
      name: String,
      myBool: Bool? = nil,
      myDouble: Double? = nil,
      myInt: Int? = nil,
      myString: String? = nil,
      myDate: Temporal.Date? = nil,
      myDateTime: Temporal.DateTime? = nil,
      myTime: Temporal.Time? = nil) {
      self.id = id
      self.name = name
      self.myBool = myBool
      self.myDouble = myDouble
      self.myInt = myInt
      self.myString = myString
      self.myDate = myDate
      self.myDateTime = myDateTime
      self.myTime = myTime
  }
}
