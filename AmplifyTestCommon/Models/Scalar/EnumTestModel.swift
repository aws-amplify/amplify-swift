//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct EnumTestModel: Model {
  public let id: String
  public var enumVal: TestEnum
  public var nullableEnumVal: TestEnum?
  public var enumList: [TestEnum]
  public var enumNullableList: [TestEnum]?
  public var nullableEnumList: [TestEnum?]
  public var nullableEnumNullableList: [TestEnum?]?

  public init(id: String = UUID().uuidString,
      enumVal: TestEnum,
      nullableEnumVal: TestEnum? = nil,
      enumList: [TestEnum] = [],
      enumNullableList: [TestEnum]? = nil,
      nullableEnumList: [TestEnum?] = [],
      nullableEnumNullableList: [TestEnum?]? = nil) {
      self.id = id
      self.enumVal = enumVal
      self.nullableEnumVal = nullableEnumVal
      self.enumList = enumList
      self.enumNullableList = enumNullableList
      self.nullableEnumList = nullableEnumList
      self.nullableEnumNullableList = nullableEnumNullableList
  }
}
