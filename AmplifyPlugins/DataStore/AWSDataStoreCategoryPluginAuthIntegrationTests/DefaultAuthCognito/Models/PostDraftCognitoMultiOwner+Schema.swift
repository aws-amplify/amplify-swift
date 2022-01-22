//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension PostDraftCognitoMultiOwner {
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
    let postDraftCognitoMultiOwner = PostDraftCognitoMultiOwner.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .owner, ownerField: "editors", identityClaim: "cognito:username", provider: .userPools, operations: [.update, .read])
    ]

    model.pluralName = "PostDraftCognitoMultiOwners"

    model.fields(
      .id(),
      .field(postDraftCognitoMultiOwner.title, is: .required, ofType: .string),
      .field(postDraftCognitoMultiOwner.content, is: .optional, ofType: .string),
      .field(postDraftCognitoMultiOwner.owner, is: .optional, ofType: .string),
      .field(postDraftCognitoMultiOwner.editors, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(postDraftCognitoMultiOwner.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(postDraftCognitoMultiOwner.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
