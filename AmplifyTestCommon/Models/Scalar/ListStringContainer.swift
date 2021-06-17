//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct ListStringContainer: Model {
  public let id: String
  public var test: String
  public var nullableString: String?
  public var stringList: [String]
  public var stringNullableList: [String]?
  public var nullableStringList: [String?]
  public var nullableStringNullableList: [String?]?

  public init(id: String = UUID().uuidString,
      test: String,
      nullableString: String? = nil,
      stringList: [String] = [],
      stringNullableList: [String]? = nil,
      nullableStringList: [String?] = [],
      nullableStringNullableList: [String?]? = nil) {
      self.id = id
      self.test = test
      self.nullableString = nullableString
      self.stringList = stringList
      self.stringNullableList = stringNullableList
      self.nullableStringList = nullableStringList
      self.nullableStringNullableList = nullableStringNullableList
  }
}
