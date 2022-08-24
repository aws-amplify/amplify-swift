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
 # 16 Schema drift scenario

 type SchemaDrift @model {
   id: ID!
   enumValue: EnumDrift
 }

 enum EnumDrift {
    ONE
    TWO
    THREE
 }

 */
public struct SchemaDrift: Model {
  public let id: String
  public var enumValue: EnumDrift?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?

  public init(id: String = UUID().uuidString,
      enumValue: EnumDrift? = nil) {
    self.init(id: id,
      enumValue: enumValue,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      enumValue: EnumDrift? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.enumValue = enumValue
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
