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
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      nestedVal: Nested,
      nullableNestedVal: Nested? = nil,
      nestedList: [Nested] = [],
      nestedNullableList: [Nested]? = nil,
      nullableNestedList: [Nested?] = [],
      nullableNestedNullableList: [Nested?]? = nil) {
    self.init(id: id,
      nestedVal: nestedVal,
      nullableNestedVal: nullableNestedVal,
      nestedList: nestedList,
      nestedNullableList: nestedNullableList,
      nullableNestedList: nullableNestedList,
      nullableNestedNullableList: nullableNestedNullableList,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      nestedVal: Nested,
      nullableNestedVal: Nested? = nil,
      nestedList: [Nested] = [],
      nestedNullableList: [Nested]? = nil,
      nullableNestedList: [Nested?] = [],
      nullableNestedNullableList: [Nested?]? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.nestedVal = nestedVal
      self.nullableNestedVal = nullableNestedVal
      self.nestedList = nestedList
      self.nestedNullableList = nestedNullableList
      self.nullableNestedList = nullableNestedList
      self.nullableNestedNullableList = nullableNestedNullableList
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}