// swiftlint:disable all
import Amplify
import Foundation

public struct PostTagsWithCompositeKey: Model {
    public let id: String
    internal var _postWithTagsCompositeKey: LazyReference<PostWithTagsCompositeKey>
    public var postWithTagsCompositeKey: PostWithTagsCompositeKey {
        get async throws {
            try await _postWithTagsCompositeKey.require()
        }
    }
    internal var _tagWithCompositeKey: LazyReference<TagWithCompositeKey>
    public var tagWithCompositeKey: TagWithCompositeKey {
        get async throws {
            try await _tagWithCompositeKey.require()
        }
    }
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?
    
    public init(id: String = UUID().uuidString,
                postWithTagsCompositeKey: PostWithTagsCompositeKey,
                tagWithCompositeKey: TagWithCompositeKey) {
        self.init(id: id,
                  postWithTagsCompositeKey: postWithTagsCompositeKey,
                  tagWithCompositeKey: tagWithCompositeKey,
                  createdAt: nil,
                  updatedAt: nil)
    }
    internal init(id: String = UUID().uuidString,
                  postWithTagsCompositeKey: PostWithTagsCompositeKey,
                  tagWithCompositeKey: TagWithCompositeKey,
                  createdAt: Temporal.DateTime? = nil,
                  updatedAt: Temporal.DateTime? = nil) {
        self.id = id
        self._postWithTagsCompositeKey = LazyReference(postWithTagsCompositeKey)
        self._tagWithCompositeKey = LazyReference(tagWithCompositeKey)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public mutating func setPostWithTagsCompositeKey(_ postWithTagsCompositeKey: PostWithTagsCompositeKey) {
        self._postWithTagsCompositeKey = LazyReference(postWithTagsCompositeKey)
    }
    
    public mutating func setTagWithCompositeKey(_ tagWithCompositeKey: TagWithCompositeKey) {
        self._tagWithCompositeKey = LazyReference(tagWithCompositeKey)
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        _postWithTagsCompositeKey = try values.decodeIfPresent(LazyReference<PostWithTagsCompositeKey>.self, forKey: .postWithTagsCompositeKey) ?? LazyReference(identifiers: nil)
        _tagWithCompositeKey = try values.decodeIfPresent(LazyReference<TagWithCompositeKey>.self, forKey: .tagWithCompositeKey) ?? LazyReference(identifiers: nil)
        createdAt = try values.decode(Temporal.DateTime?.self, forKey: .createdAt)
        updatedAt = try values.decode(Temporal.DateTime?.self, forKey: .updatedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(_postWithTagsCompositeKey, forKey: .postWithTagsCompositeKey)
        try container.encode(_tagWithCompositeKey, forKey: .tagWithCompositeKey)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
