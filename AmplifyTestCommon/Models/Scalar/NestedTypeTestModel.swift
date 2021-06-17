//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct NestedTypeTestModel: Model {
  public let id: String
  public var nestedVal: Nested
  public var nullableNestedVal: Nested?
  public var nestedList: [Nested]
  public var nestedNullableList: [Nested]?
  public var nullableNestedList: [Nested?]
  public var nullableNestedNullableList: [Nested?]?

  public init(id: String = UUID().uuidString,
      nestedVal: Nested,
      nullableNestedVal: Nested? = nil,
      nestedList: [Nested] = [],
      nestedNullableList: [Nested]? = nil,
      nullableNestedList: [Nested?] = [],
      nullableNestedNullableList: [Nested?]? = nil) {
      self.id = id
      self.nestedVal = nestedVal
      self.nullableNestedVal = nullableNestedVal
      self.nestedList = nestedList
      self.nestedNullableList = nestedNullableList
      self.nullableNestedList = nullableNestedList
      self.nullableNestedNullableList = nullableNestedNullableList
  }
}
