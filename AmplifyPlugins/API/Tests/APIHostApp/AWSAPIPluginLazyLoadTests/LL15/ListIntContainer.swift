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
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      test: Int,
      nullableInt: Int? = nil,
      intList: [Int] = [],
      intNullableList: [Int]? = nil,
      nullableIntList: [Int?] = [],
      nullableIntNullableList: [Int?]? = nil) {
    self.init(id: id,
      test: test,
      nullableInt: nullableInt,
      intList: intList,
      intNullableList: intNullableList,
      nullableIntList: nullableIntList,
      nullableIntNullableList: nullableIntNullableList,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      test: Int,
      nullableInt: Int? = nil,
      intList: [Int] = [],
      intNullableList: [Int]? = nil,
      nullableIntList: [Int?] = [],
      nullableIntNullableList: [Int?]? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.test = test
      self.nullableInt = nullableInt
      self.intList = intList
      self.intNullableList = intNullableList
      self.nullableIntList = nullableIntList
      self.nullableIntNullableList = nullableIntNullableList
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}