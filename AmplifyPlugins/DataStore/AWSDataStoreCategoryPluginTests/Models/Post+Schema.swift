//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension Post {

    // MARK: - CodingKeys
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case title
        case content
        case createdAt
        case updatedAt
        case draft
        case comments
    }

    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let post = Post.CodingKeys.self

        model.fields(
            .id(),
            .field(post.title, is: .required, ofType: .string),
            .field(post.content, is: .required, ofType: .string),
            .field(post.createdAt, is: .required, ofType: .dateTime),
            .field(post.updatedAt, is: .optional, ofType: .dateTime),
            .field(post.draft, is: .required, ofType: .bool),
            .connected(post.comments, .oneToMany(Comment.self), withName: "PostComments")
        )
    }

}
