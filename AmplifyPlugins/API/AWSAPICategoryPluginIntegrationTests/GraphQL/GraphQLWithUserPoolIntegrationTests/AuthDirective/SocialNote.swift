//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
                owner: String?) {
        self.id = id
        self.content = content
        self.owner = owner
    }
    public enum CodingKeys: String, ModelKey {
        case id
        case content
        case owner
    }
    public static let keys = CodingKeys.self

    public static let schema = defineSchema { model in
        let socialNote = SocialNote.keys
        model.authRules = [
            rule(allow: .owner, operations: [.create, .update, .delete])
        ]
        model.fields(
            .id(),
            .field(socialNote.content, is: .required, ofType: .string),
            .field(socialNote.owner, is: .optional, ofType: .string))
    }
}
