//
//  RelationalModels.swift
//  DataStoreDocsApp
//
//  Created by Law, Michael on 10/5/22.
//

import Foundation
import Amplify

struct RelationalModels {
    public struct Post: Model {
      public let id: String
      public var title: String
      public var rating: Int
      public var status: PostStatus
      public var comments: List<Comment>?
      public var createdAt: Temporal.DateTime?
      public var updatedAt: Temporal.DateTime?
      
      public init(id: String = UUID().uuidString,
          title: String,
          rating: Int,
          status: PostStatus,
          comments: List<Comment>? = []) {
        self.init(id: id,
          title: title,
          rating: rating,
          status: status,
          comments: comments,
          createdAt: nil,
          updatedAt: nil)
      }
      internal init(id: String = UUID().uuidString,
          title: String,
          rating: Int,
          status: PostStatus,
          comments: List<Comment>? = [],
          createdAt: Temporal.DateTime? = nil,
          updatedAt: Temporal.DateTime? = nil) {
          self.id = id
          self.title = title
          self.rating = rating
          self.status = status
          self.comments = comments
          self.createdAt = createdAt
          self.updatedAt = updatedAt
      }
        
      // MARK: - CodingKeys
       public enum CodingKeys: String, ModelKey {
        case id
        case title
        case rating
        case status
        case comments
        case createdAt
        case updatedAt
      }
      
      public static let keys = CodingKeys.self
      //  MARK: - ModelSchema
      
      public static let schema = defineSchema { model in
        let post = Post.keys
        
        model.authRules = [
          rule(allow: .public, operations: [.create, .update, .delete, .read])
        ]
        
        model.pluralName = "Posts"
        
        model.fields(
          .id(),
          .field(post.title, is: .required, ofType: .string),
          .field(post.rating, is: .required, ofType: .int),
          .field(post.status, is: .required, ofType: .enum(type: PostStatus.self)),
          .hasMany(post.comments, is: .optional, ofType: Comment.self, associatedWith: Comment.keys.post),
          .field(post.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
          .field(post.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
        )
        }
    }
    
    public enum PostStatus: String, EnumPersistable {
      case active = "ACTIVE"
      case inactive = "INACTIVE"
    }

    public struct Comment: Model {
      public let id: String
      public var content: String?
      public var post: Post?
      public var createdAt: Temporal.DateTime?
      public var updatedAt: Temporal.DateTime?
      
      public init(id: String = UUID().uuidString,
          content: String? = nil,
          post: Post? = nil) {
        self.init(id: id,
          content: content,
          post: post,
          createdAt: nil,
          updatedAt: nil)
      }
      internal init(id: String = UUID().uuidString,
          content: String? = nil,
          post: Post? = nil,
          createdAt: Temporal.DateTime? = nil,
          updatedAt: Temporal.DateTime? = nil) {
          self.id = id
          self.content = content
          self.post = post
          self.createdAt = createdAt
          self.updatedAt = updatedAt
      }
        
      // MARK: - CodingKeys
       public enum CodingKeys: String, ModelKey {
        case id
        case content
        case post
        case createdAt
        case updatedAt
      }
      
      public static let keys = CodingKeys.self
      //  MARK: - ModelSchema
      
      public static let schema = defineSchema { model in
        let comment = Comment.keys
        
        model.pluralName = "Comments"
        
        model.fields(
          .id(),
          .field(comment.content, is: .optional, ofType: .string),
          .belongsTo(comment.post, is: .optional, ofType: Post.self, targetName: "postCommentsId"),
          .field(comment.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
          .field(comment.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
        )
        }
    }
    func savingRelations() async {
        let post = Post(
            title: "My post with comments",
            rating: 5,
            status: .active
        )
        
        let commentWithPost = Comment(
            content: "Loving Amplify DataStore",
            post: post
        )
        
        do {
            let savedPost = try await Amplify.DataStore.save(post)
            let savedCommentWithPost = try await Amplify.DataStore.save(commentWithPost)
        } catch let error as DataStoreError {
            print("Failed with error \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func saveRelationCombine() {
        let post = Post(
            title: "My post with comments",
            rating: 5,
            status: .active
        )

        let commentWithPost = Comment(
            content: "Loving Amplify DataStore",
            post: post)

        let sink = Amplify.Publisher.create { try await Amplify.DataStore.save(post) }
            .flatMap { Amplify.Publisher.create { try await Amplify.DataStore.save(commentWithPost) } }
            .sink {
                if case let .failure(error) = $0 {
                    print("Error adding post and comment - \(error.localizedDescription)")
                }
            }
            receiveValue: {
                print("Post and comment saved!")
            }
    }
    
    func queryingRelations() async {
        do {
            guard let queriedPost = try await Amplify.DataStore.query(Post.self, byId: "123"),
                  let comments = queriedPost.comments else {
                return
            }
            // call fetch to lazy load the postResult before accessing its result
            try await comments.fetch()
            for comment in comments {
                print("\(comment)")
            }
            
            let excitedComments = comments
                .compactMap { $0.content }
                .filter { $0.contains("Wow!") }
            
            
        } catch let error as DataStoreError {
            print("Failed to query \(error)")
        } catch let error as CoreError {
            print("Failed to fetch \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
        
        
    }
    
    func queryRelationsCombine() {
        let sink = Amplify.Publisher.create { try await Amplify.DataStore.query(Post.self, byId: "123") }.sink {
            if case let .failure(error) = $0 {
                print("Error retrieving post \(error.localizedDescription)")
            }
        } receiveValue: { queriedPost in
            guard let queriedPost = queriedPost,
                  let comments = queriedPost.comments else {
                return
            }
            // call fetch to lazy load the postResult before accessing its result
            Task {
                do {
                    try await comments.fetch()
                    for comment in comments {
                        print("\(comment)")
                    }
                    
                    let excitedComments = comments
                        .compactMap { $0.content }
                        .filter { $0.contains("Wow!") }
                } catch let error as CoreError {
                    print("Failed to fetch \(error)")
                } catch {
                    print("Unexpected error \(error)")
                }
            }
        }
    }
    
    func deletingRelations() async {
        do {
            guard let postWithComments = try await Amplify.DataStore.query(Post.self, byId: "123") else {
                print("No post found")
                return
            }
            try await Amplify.DataStore.delete(postWithComments)
            print("Post with id 123 deleted with success")
        } catch let error as DataStoreError {
            print("Failed with error \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func deletingRelationsCombine() {
        let sink = Amplify.Publisher.create {
            guard let postWithComments = try await Amplify.DataStore.query(Post.self, byId: "123") else {
                return
            }
            try await Amplify.DataStore.delete(postWithComments)
        }.sink {
            if case let .failure(error) = $0 {
                print("Error deleting post and comments - \(error)")
            }
        } receiveValue: {
            print("Post with id 123 deleted with success")
        }
    }
    
}
