//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension Comment {

    // MARK: - CodingKeys
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case content
        case createdAt
        case post
    }

    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let comment = Comment.CodingKeys.self

        model.fields(
            .id(),
            .field(comment.content, is: .required, ofType: .string),
            .field(comment.createdAt, is: .required, ofType: .dateTime),
            .connected(comment.post, .manyToOne(Post.self), is: .required, withName: "PostComments")
        )
    }

}
