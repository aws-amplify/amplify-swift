//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Comment: Model {
    public let id: String
    public var content: String
    public var createdAt: Temporal.DateTime
    internal var _post: LazyReference<Post>
    public var post: Post {
        get async throws {
            try await _post.require()
        }
    }
    
    public init(id: String = UUID().uuidString,
                content: String,
                createdAt: Temporal.DateTime,
                post: Post) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self._post = LazyReference(post)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        content = try values.decode(String.self, forKey: .content)
        createdAt = try values.decode(Temporal.DateTime.self, forKey: .createdAt)
        _post = try values.decode(LazyReference<Post>.self, forKey: .post)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(_post, forKey: .post)
    }
}
