//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Blog {
    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case content
        case createdAt
        case owner
        case authorNotes
    }

    public static let keys = CodingKeys.self
    //  MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let blog = Blog.keys

        model.pluralName = "Blogs"

        model.authRules = [
            rule(allow: .owner, ownerField: blog.owner, operations: [.create, .read]),
            rule(allow: .groups, groups: ["Admin"]),
        ]

        model.fields(
            .id(),
            .field(blog.content, is: .required, ofType: .string),
            .field(blog.createdAt, is: .required, ofType: .dateTime),
            .field(blog.owner, is: .optional, ofType: .string),
            .field(blog.authorNotes,
                   is: .optional,
                   ofType: .string,
                   authRules: [rule(allow: .owner, ownerField: blog.owner, operations: [.update])]
            )
        )
    }
}
