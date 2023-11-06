//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension TodoExplicitOwnerField {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case owner
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let todoExplicitOwnerField = TodoExplicitOwnerField.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.read, .create, .update, .delete])
    ]
    
    model.listPluralName = "TodoExplicitOwnerFields"
    model.syncPluralName = "TodoExplicitOwnerFields"
    
    model.attributes(
      .primaryKey(fields: [todoExplicitOwnerField.id])
    )
    
    model.fields(
      .field(todoExplicitOwnerField.id, is: .required, ofType: .string),
      .field(todoExplicitOwnerField.content, is: .required, ofType: .string),
      .field(todoExplicitOwnerField.owner, is: .optional, ofType: .string),
      .field(todoExplicitOwnerField.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todoExplicitOwnerField.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension TodoExplicitOwnerField: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
