//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// MARK: - CodingKeys

extension Post {
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case title
        case content
        case createdAt
        case updatedAt
        case draft
        case comments
    }
}

// MARK: - ModelMetadata

extension Post: ModelMetadata {
    public static let primaryKey: ModelKey = CodingKeys.id
    public static let properties: ModelProperties = CodingKeys.allCases
}

// MARK: - ModelProperty

extension Post.CodingKeys: ModelProperty {
    public var metadata: PropertyMetadata {
        switch self {
        case .id:
            return property(type: .string, attributes: .primaryKey)
        case .title:
            return property(type: .string)
        case .content:
            return property(type: .string)
        case .createdAt:
            return property(type: .date)
        case .updatedAt:
            return property(type: .date, optional: true)
        case .draft:
            return property(type: .boolean)
        case .comments:
            return property(type: .collection(.model(Comment.self)),
                            attributes: .connection(name: "PostComment"))
        }
    }
}
