//
//  SyncingDataToCloud.swift
//  DataStoreDocsApp
//
//  Created by Law, Michael on 10/5/22.
//

import Foundation
import Amplify
import AWSDataStorePlugin

struct SyncingDataToCloud {
    public enum PostStatus: String, EnumPersistable {
        case active = "ACTIVE"
        case inactive = "INACTIVE"
    }
    public struct Post: Model {
        public let id: String
        public var title: String
        public var rating: Int?
        public var status: PostStatus?
        public var editors: List<PostEditor>?
        public var createdAt: Temporal.DateTime?
        public var updatedAt: Temporal.DateTime?
        
        public init(id: String = UUID().uuidString,
                    title: String,
                    rating: Int? = nil,
                    status: PostStatus? = nil,
                    editors: List<PostEditor>? = []) {
            self.init(id: id,
                      title: title,
                      rating: rating,
                      status: status,
                      editors: editors,
                      createdAt: nil,
                      updatedAt: nil)
        }
        internal init(id: String = UUID().uuidString,
                      title: String,
                      rating: Int? = nil,
                      status: PostStatus? = nil,
                      editors: List<PostEditor>? = [],
                      createdAt: Temporal.DateTime? = nil,
                      updatedAt: Temporal.DateTime? = nil) {
            self.id = id
            self.title = title
            self.rating = rating
            self.status = status
            self.editors = editors
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
        
        // MARK: - CodingKeys
        public enum CodingKeys: String, ModelKey {
            case id
            case title
            case rating
            case status
            case editors
            case createdAt
            case updatedAt
        }
        
        public static let keys = CodingKeys.self
        //  MARK: - ModelSchema
        
        public static let schema = defineSchema { model in
            let post = Post.keys
            
            model.pluralName = "Posts"
            
            model.fields(
                .id(),
                .field(post.title, is: .required, ofType: .string),
                .field(post.rating, is: .optional, ofType: .int),
                .field(post.status, is: .optional, ofType: .enum(type: PostStatus.self)),
                .hasMany(post.editors, is: .optional, ofType: PostEditor.self, associatedWith: PostEditor.keys.post),
                .field(post.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
                .field(post.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
            )
        }
    }
    
    public struct PostEditor: Model {
        public let id: String
        public var post: Post
        public var user: User
        public var createdAt: Temporal.DateTime?
        public var updatedAt: Temporal.DateTime?
        
        public init(id: String = UUID().uuidString,
                    post: Post,
                    user: User) {
            self.init(id: id,
                      post: post,
                      user: user,
                      createdAt: nil,
                      updatedAt: nil)
        }
        internal init(id: String = UUID().uuidString,
                      post: Post,
                      user: User,
                      createdAt: Temporal.DateTime? = nil,
                      updatedAt: Temporal.DateTime? = nil) {
            self.id = id
            self.post = post
            self.user = user
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
        // MARK: - CodingKeys
        public enum CodingKeys: String, ModelKey {
            case id
            case post
            case user
            case createdAt
            case updatedAt
        }
        
        public static let keys = CodingKeys.self
        //  MARK: - ModelSchema
        
        public static let schema = defineSchema { model in
            let postEditor = PostEditor.keys
            
            model.pluralName = "PostEditors"
            
            model.attributes(
                .index(fields: ["postID"], name: "byPost"),
                .index(fields: ["userID"], name: "byUser")
            )
            
            model.fields(
                .id(),
                .belongsTo(postEditor.post, is: .required, ofType: Post.self, targetName: "postID"),
                .belongsTo(postEditor.user, is: .required, ofType: User.self, targetName: "userID"),
                .field(postEditor.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
                .field(postEditor.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
            )
        }
    }
    
    public struct User: Model {
        public let id: String
        public var username: String
        public var posts: List<PostEditor>?
        public var createdAt: Temporal.DateTime?
        public var updatedAt: Temporal.DateTime?
        
        public init(id: String = UUID().uuidString,
                    username: String,
                    posts: List<PostEditor>? = []) {
            self.init(id: id,
                      username: username,
                      posts: posts,
                      createdAt: nil,
                      updatedAt: nil)
        }
        internal init(id: String = UUID().uuidString,
                      username: String,
                      posts: List<PostEditor>? = [],
                      createdAt: Temporal.DateTime? = nil,
                      updatedAt: Temporal.DateTime? = nil) {
            self.id = id
            self.username = username
            self.posts = posts
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
        // MARK: - CodingKeys
        public enum CodingKeys: String, ModelKey {
            case id
            case username
            case posts
            case createdAt
            case updatedAt
        }
        
        public static let keys = CodingKeys.self
        //  MARK: - ModelSchema
        
        public static let schema = defineSchema { model in
            let user = User.keys
            
            model.pluralName = "Users"
            
            model.fields(
                .id(),
                .field(user.username, is: .required, ofType: .string),
                .hasMany(user.posts, is: .optional, ofType: PostEditor.self, associatedWith: PostEditor.keys.user),
                .field(user.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
                .field(user.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
            )
        }
    }
    
    let post = Post(title: "title")
    
    func updateAndDeleteWithPredicate() async {
        do {
            try await Amplify.DataStore.save(
                post,
                where: Post.keys.title.beginsWith("[Amplify]"))
            print("Post updated successfully!")
        } catch let error as DataStoreError {
            print("Could not update post, maybe the title has been changed?")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    func updateAndDeleteWithPredicateCombine() {
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.save(
                post,
                where: Post.keys.title.beginsWith("[Amplify]"))
        }.sink {
            if case let .failure(error) = $0 {
                print("Could not update post, maybe the title has been changed?")
            }
        }
    receiveValue: { _ in
        print("Post updated successfully!")
    }
    }
    
    func tranditionalLocalCondition() async throws {
        // Tests only against the local state
        if post.title.starts(with: "[Amplify]") {
            let savedPost = try await Amplify.DataStore.save(post)
        }
        
        // Only applies the update if the data in the remote backend satisfies the criteria
        let savedPost = try await Amplify.DataStore.save(
            post,
            where: Post.keys.title.beginsWith("[Amplify]")
        )
    }
    
    func clearLocalData() async {
        let isSignedOut = HubFilters.forEventName(HubPayload.EventName.Auth.signedOut)
        let token = Amplify.Hub.listen(to: .auth, isIncluded: isSignedOut) { payload in
            Task {
                do {
                    try await Amplify.DataStore.clear()
                    print("Local data cleared successfully.")
                } catch let error as DataStoreError {
                    print("Error clearing DataStore \(error)")
                } catch {
                    print("Unexpected error \(error)")
                }
            }
        }
    }
    
    // TODO: need to fix this Combine code snippet
//    func clearLocalDataCombine() {
//        let isSignedOut = HubFilters.forEventName(HubPayload.EventName.Auth.signedOut)
//        let sink = Amplify.Hub.publisher(for: .auth)
//            .setFailureType(to: DataStoreError.self)
//            .filter { isSignedOut($0) }
//            .flatMap { _ in Amplify.Publisher.create(try await Amplify.DataStore.clear()) }
//            .sink {
//                if case let .failure(error) = $0 {
//                    print("Local data not cleared \(error)")
//                }
//            }
//            receiveValue: {  in
//                print("Local data cleared successfully.")
//            }
//    }
    
    func selectiveSync() {
        let syncExpr1 = DataStoreSyncExpression.syncExpression(Post.schema) {
            Post.keys.rating.gt(5)
        }
        let syncExpr2 = DataStoreSyncExpression.syncExpression(Comment.schema) {
            Comment.keys.status.eq("active")
        }
        try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: AmplifyModels(),
                                                   configuration: .custom(
                                syncExpressions: [syncExpr1, syncExpr2])))
    }
}
