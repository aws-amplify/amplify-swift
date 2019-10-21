//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// MARK: - CodingKeys

extension Comment {
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case content
        case createdAt
        case post
    }
}

// MARK: - ModelMetadata

extension Comment: ModelMetadata {
    public static let primaryKey: ModelKey = CodingKeys.id
    public static let properties: ModelProperties = CodingKeys.allCases
}

// MARK: - ModelProperty

extension Comment.CodingKeys: ModelProperty {
    public var metadata: PropertyMetadata {
        switch self {
        case .id:
            return property(type: .string, attributes: .primaryKey)
        case .content:
            return property(type: .string)
        case .createdAt:
            return property(type: .date)
        case .post:
            return property(type: .model(Post.self),
                            attributes: .connection(name: "PostComment"))
        }
    }
}
