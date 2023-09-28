//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension TodoCognitoMultiOwner {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case content
    case owner
    case editors
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let todoCognitoMultiOwner = TodoCognitoMultiOwner.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .owner, ownerField: "editors", identityClaim: "cognito:username", provider: .userPools, operations: [.update, .read])
    ]
    
    model.listPluralName = "TodoCognitoMultiOwners"
    model.syncPluralName = "TodoCognitoMultiOwners"
    
    model.attributes(
      .primaryKey(fields: [todoCognitoMultiOwner.id])
    )
    
    model.fields(
      .field(todoCognitoMultiOwner.id, is: .required, ofType: .string),
      .field(todoCognitoMultiOwner.title, is: .required, ofType: .string),
      .field(todoCognitoMultiOwner.content, is: .optional, ofType: .string),
      .field(todoCognitoMultiOwner.owner, is: .optional, ofType: .string),
      .field(todoCognitoMultiOwner.editors, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(todoCognitoMultiOwner.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todoCognitoMultiOwner.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension TodoCognitoMultiOwner: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
