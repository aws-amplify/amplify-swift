// swiftlint:disable all
import Amplify
import Foundation

public struct Comment7: Model {
    public let commentId: String
    public let content: String
    internal var _post: LazyModel<Post7>
    public var post: Post7? {
        get async throws {
            try await _post.get()
        }
    }
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?
    
    public init(commentId: String,
                content: String,
                post: Post7? = nil) {
        self.init(commentId: commentId,
                  content: content,
                  post: post,
                  createdAt: nil,
                  updatedAt: nil)
    }
    internal init(commentId: String,
                  content: String,
                  post: Post7? = nil,
                  createdAt: Temporal.DateTime? = nil,
                  updatedAt: Temporal.DateTime? = nil) {
        self.commentId = commentId
        self.content = content
        self._post = LazyModel(element: post)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public mutating func setPost(_ post: Post7?) {
        self._post = LazyModel(element: post)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        commentId = try values.decode(String.self, forKey: .commentId)
        content = try values.decode(String.self, forKey: .content)
        _post = try values.decode(LazyModel<Post7>.self, forKey: .post)
        createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
        updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(commentId, forKey: .commentId)
        try container.encode(content, forKey: .content)
        try container.encode(_post, forKey: .post)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
