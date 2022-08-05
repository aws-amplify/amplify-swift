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
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      enumVal: TestEnum,
      nullableEnumVal: TestEnum? = nil,
      enumList: [TestEnum] = [],
      enumNullableList: [TestEnum]? = nil,
      nullableEnumList: [TestEnum?] = [],
      nullableEnumNullableList: [TestEnum?]? = nil) {
    self.init(id: id,
      enumVal: enumVal,
      nullableEnumVal: nullableEnumVal,
      enumList: enumList,
      enumNullableList: enumNullableList,
      nullableEnumList: nullableEnumList,
      nullableEnumNullableList: nullableEnumNullableList,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      enumVal: TestEnum,
      nullableEnumVal: TestEnum? = nil,
      enumList: [TestEnum] = [],
      enumNullableList: [TestEnum]? = nil,
      nullableEnumList: [TestEnum?] = [],
      nullableEnumNullableList: [TestEnum?]? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.enumVal = enumVal
      self.nullableEnumVal = nullableEnumVal
      self.enumList = enumList
      self.enumNullableList = enumNullableList
      self.nullableEnumList = nullableEnumList
      self.nullableEnumNullableList = nullableEnumNullableList
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}