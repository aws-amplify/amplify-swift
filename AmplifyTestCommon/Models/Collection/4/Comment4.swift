//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Comment4: Model {
    public let id: String
    public var content: String
    internal var _post: LazyReference<Post4>
    public var post: Post4? {
        get async throws {
            try await _post.get()
        }
    }
    
    public init(id: String = UUID().uuidString,
                content: String,
                post: Post4? = nil) {
        self.id = id
        self.content = content
        self._post = LazyReference(post)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        content = try values.decode(String.self, forKey: .content)
        _post = try values.decodeIfPresent(LazyReference<Post4>.self, forKey: .post) ?? LazyReference(identifiers: nil)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(_post, forKey: .post)
    }
}
