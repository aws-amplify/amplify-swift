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
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      test: String,
      nullableString: String? = nil,
      stringList: [String] = [],
      stringNullableList: [String]? = nil,
      nullableStringList: [String?] = [],
      nullableStringNullableList: [String?]? = nil) {
    self.init(id: id,
      test: test,
      nullableString: nullableString,
      stringList: stringList,
      stringNullableList: stringNullableList,
      nullableStringList: nullableStringList,
      nullableStringNullableList: nullableStringNullableList,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      test: String,
      nullableString: String? = nil,
      stringList: [String] = [],
      stringNullableList: [String]? = nil,
      nullableStringList: [String?] = [],
      nullableStringNullableList: [String?]? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.test = test
      self.nullableString = nullableString
      self.stringList = stringList
      self.stringNullableList = stringNullableList
      self.nullableStringList = nullableStringList
      self.nullableStringNullableList = nullableStringNullableList
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}