//
//  GettingStarted.swift
//  DataStoreDocsApp
//
//  Created by Law, Michael on 10/5/22.
//

import Foundation
import Amplify

struct GettingStarted {
    public enum PostStatus: String, EnumPersistable {
      case active = "ACTIVE"
      case inactive = "INACTIVE"
    }
    public struct Post: Model {
      public let id: String
      public var title: String
      public var status: PostStatus
      public var rating: Int?
      public var content: String?
      public var createdAt: Temporal.DateTime?
      public var updatedAt: Temporal.DateTime?
      
      public init(id: String = UUID().uuidString,
          title: String,
          status: PostStatus,
          rating: Int? = nil,
          content: String? = nil) {
        self.init(id: id,
          title: title,
          status: status,
          rating: rating,
          content: content,
          createdAt: nil,
          updatedAt: nil)
      }
      internal init(id: String = UUID().uuidString,
          title: String,
          status: PostStatus,
          rating: Int? = nil,
          content: String? = nil,
          createdAt: Temporal.DateTime? = nil,
          updatedAt: Temporal.DateTime? = nil) {
          self.id = id
          self.title = title
          self.status = status
          self.rating = rating
          self.content = content
          self.createdAt = createdAt
          self.updatedAt = updatedAt
      }

      // MARK: - CodingKeys
       public enum CodingKeys: String, ModelKey {
        case id
        case title
        case status
        case rating
        case content
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
          .field(post.status, is: .required, ofType: .enum(type: PostStatus.self)),
          .field(post.rating, is: .optional, ofType: .int),
          .field(post.content, is: .optional, ofType: .string),
          .field(post.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
          .field(post.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
        )
        }
    }

    // MARK: - Getting Started
    
    func writingToTheDatabase() async throws {
        let post = Post(title: "Create an Amplify DataStore app",
                        status: .active)

        do {
            try await Amplify.DataStore.save(post)
            print("Post saved successfully!")
        } catch let error as DataStoreError {
            print("Error saving post \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func writingToTheDatabaseCombine() {
        let post = Post(title: "Create an Amplify DataStore app",
                        status: .active)
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.save(post)
        }.sink {
            if case let .failure(error) = $0 {
                print("Error saving post \(error)")
            }
        }
        receiveValue: {
            print("Post saved successfully! \($0)")
        }
    }
    
    func readingFromDatabase() async throws {
        do {
            let posts = try await Amplify.DataStore.query(Post.self)
            print("Posts retrieved successfully: \(posts)")
        } catch let error as DataStoreError {
            print("Error retrieving posts \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func readingFromDatabaseCombine() {
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.query(Post.self)
        }.sink {
            if case let .failure(error) = $0 {
                print("Error retrieving posts \(error)")
            }
        }
        receiveValue: { posts in
            print("Posts retrieved successfully: \(posts)")
        }
    }
}
