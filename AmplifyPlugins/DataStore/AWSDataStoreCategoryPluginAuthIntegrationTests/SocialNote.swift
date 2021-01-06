//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public struct SocialNote: Model {
  public let id: String
  public var content: String
  public var owner: String?

  public init(id: String = UUID().uuidString,
              content: String,
              owner: String? = nil) {
      self.id = id
      self.content = content
      self.owner = owner
  }
}

extension SocialNote {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case owner
  }

  public static let keys = CodingKeys.self

  public static let schema = defineSchema { model in
    let socialNote = SocialNote.keys

    model.authRules = [
      rule(allow: .owner,
           ownerField: "owner",
           identityClaim: "cognito:username",
           operations: [.create, .update, .delete])
    ]

    model.pluralName = "SocialNotes"

    model.fields(
      .id(),
      .field(socialNote.content, is: .required, ofType: .string),
      .field(socialNote.owner, is: .optional, ofType: .string)
    )
    }
}

final public class SocialNoteModelRegistration: AmplifyModelRegistration {
  public let version: String = "1"

  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: SocialNote.self)
  }
}
