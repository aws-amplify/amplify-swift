// swiftlint:disable all
import Amplify
import Foundation

public struct CommentWithCompositeKey: Model {
    public let id: String
    public let content: String
    internal var _post: LazyModel<PostWithCompositeKey>
    public var post: PostWithCompositeKey? {
        get async throws {
            try await _post.get()
        }
    }
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?
    
    public init(id: String = UUID().uuidString,
                content: String,
                post: PostWithCompositeKey? = nil) {
        self.init(id: id,
                  content: content,
                  post: post,
                  createdAt: nil,
                  updatedAt: nil)
    }
    internal init(id: String = UUID().uuidString,
                  content: String,
                  post: PostWithCompositeKey? = nil,
                  createdAt: Temporal.DateTime? = nil,
                  updatedAt: Temporal.DateTime? = nil) {
        self.id = id
        self.content = content
        self._post = LazyModel(element: post)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public mutating func setPost(_ post: PostWithCompositeKey?) {
        self._post = LazyModel(element: post)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        content = try values.decode(String.self, forKey: .content)
        _post = try values.decode(LazyModel<PostWithCompositeKey>.self, forKey: .post)
        createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
        updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(_post, forKey: .post)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
