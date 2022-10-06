//
//  ManyToMany.swift
//  DataStoreDocsApp
//
//  Created by Law, Michael on 10/5/22.
//

import Foundation
import Amplify

struct ManyToMany {
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
    
    func manyToMany() async {
        let post = Post(
            title: "My first post",
            status: .active
        )
        let user = User(
            username: "Nadia"
        )
        let postEditor = PostEditor(
            post: post,
            user: user
        )
        do {
            try await Amplify.DataStore.save(post)
            try await Amplify.DataStore.save(user)
            try await Amplify.DataStore.save(postEditor)
            print("Saved post, user, and postEditor!")
        } catch let error as DataStoreError {
            print("Failed with error \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func manyToManyCombine() {
        let post = Post(
            title: "My first post",
            status: .active
        )
        let user = User(
            username: "Nadia"
        )
        let postEditor = PostEditor(
            post: post,
            user: user
        )
        let sink = Amplify.Publisher.create{ try await Amplify.DataStore.save(post) }
            .flatMap { _ in
                Amplify.Publisher.create { try await Amplify.DataStore.save(user) }
            }
            .flatMap { _ in
                Amplify.Publisher.create { try await Amplify.DataStore.save(postEditor) }
            }
            .sink {
                if case let .failure(error) = $0 {
                    print("Error saving post, user and postEditor: \(error.localizedDescription)")
                }
            }
            receiveValue: { _ in
                print("Saved user, post and postEditor!")
            }
    }
}
