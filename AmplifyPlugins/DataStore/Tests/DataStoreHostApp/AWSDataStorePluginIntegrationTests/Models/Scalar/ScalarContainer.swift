//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct ScalarContainer: Model {
  public let id: String
  public var myString: String?
  public var myInt: Int?
  public var myDouble: Double?
  public var myBool: Bool?
  public var myDate: Temporal.Date?
  public var myTime: Temporal.Time?
  public var myDateTime: Temporal.DateTime?
  public var myTimeStamp: Int?
  public var myEmail: String?
  public var myJSON: String?
  public var myPhone: String?
  public var myURL: String?
  public var myIPAddress: String?

  public init(id: String = UUID().uuidString,
      myString: String? = nil,
      myInt: Int? = nil,
      myDouble: Double? = nil,
      myBool: Bool? = nil,
      myDate: Temporal.Date? = nil,
      myTime: Temporal.Time? = nil,
      myDateTime: Temporal.DateTime? = nil,
      myTimeStamp: Int? = nil,
      myEmail: String? = nil,
      myJSON: String? = nil,
      myPhone: String? = nil,
      myURL: String? = nil,
      myIPAddress: String? = nil) {
      self.id = id
      self.myString = myString
      self.myInt = myInt
      self.myDouble = myDouble
      self.myBool = myBool
      self.myDate = myDate
      self.myTime = myTime
      self.myDateTime = myDateTime
      self.myTimeStamp = myTimeStamp
      self.myEmail = myEmail
      self.myJSON = myJSON
      self.myPhone = myPhone
      self.myURL = myURL
      self.myIPAddress = myIPAddress
  }
}
