//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct ListIntContainer: Model {
  public let id: String
  public var test: Int
  public var nullableInt: Int?
  public var intList: [Int]
  public var intNullableList: [Int]?
  public var nullableIntList: [Int?]
  public var nullableIntNullableList: [Int?]?

  public init(id: String = UUID().uuidString,
      test: Int,
      nullableInt: Int? = nil,
      intList: [Int] = [],
      intNullableList: [Int]? = nil,
      nullableIntList: [Int?] = [],
      nullableIntNullableList: [Int?]? = nil) {
      self.id = id
      self.test = test
      self.nullableInt = nullableInt
      self.intList = intList
      self.intNullableList = intNullableList
      self.nullableIntList = nullableIntList
      self.nullableIntNullableList = nullableIntNullableList
  }
}
