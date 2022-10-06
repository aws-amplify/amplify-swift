//
//  ManipulatingData.swift
//  DataStoreDocsApp
//
//  Created by Law, Michael on 10/5/22.
//

import Foundation
import Amplify
import SwiftUI
import Combine

struct ManipulatingData {
    let post = Post(title: "My first post", status: .active, content: "Amplify.DataStore is awesome!")

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

    func createAndUpdate() async {
        do {
            try await Amplify.DataStore.save(
                Post(title: "My first post",
                     status: .active,
                     content: "Amplify.DataStore is awesome!")
            )
            print("Created a new post successfully")
        } catch let error as DataStoreError {
            print("Error creating post - \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func createAndUpdateCombine() {
        let saveSink = Amplify.Publisher.create {
            try await Amplify.DataStore.save(
                Post(title: "My first post",
                     status: .active,
                     content: "Amplify.DataStore is awesome!")
            )}.sink {
                if case let .failure(error) = $0 {
                    print("Error updating post - \(error.localizedDescription)")
                }
            } receiveValue: {
                print("Updated the existing post: \($0)")
            }
    }
    
    func update() async {
        var existingPost: Post = Post(title: "My first post", status: .active, content: "Amplify.DataStore is awesome!")
        existingPost.title = "[updated] My first post"
        do {
            try await Amplify.DataStore.save(existingPost)
            print("Updated the existing post")
        } catch let error as DataStoreError {
            print("Error updating post - \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func updateCombine() {
        var existingPost: Post = Post(title: "My first post", status: .active, content: "Amplify.DataStore is awesome!")
        existingPost.title = "[updated] My first post"
        let postForUpdate = existingPost
        let saveSink = Amplify.Publisher.create {
            try await Amplify.DataStore.save(postForUpdate)
        }.sink {
            if case let .failure(error) = $0 {
                print("Error updating post - \(error)")
            }
        }
        receiveValue: {
            print("Updated the existing post: \($0)")
        }
    }
    
    func delete() async {
        do {
            try await Amplify.DataStore.delete(post)
            print("Post deleted!")
        } catch let error as DataStoreError {
            print("Error deleting post - \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func deleteCombine() {
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.delete(post)
        }.sink {
            if case let .failure(error) = $0 {
                print("Fetch session failed with error \(error)")
            }
        }
        receiveValue: {
            print("Post deleted!")
        }
    }
    
    func deleteWithId() async {
        do {
            try await Amplify.DataStore.delete(Post.self, withId: "123")
            print("Post deleted!")
        } catch let error as DataStoreError {
            print("Error deleting post - \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func deleteWithCombine() {
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.delete(Post.self, withId: "123")
        }.sink {
            if case let .failure(error) = $0 {
                print("Error deleting post - \(error)")
            }
        }
        receiveValue: {
            print("Post deleted!")
        }
    }
    
    func queryData() async {
        do {
            let result = try await Amplify.DataStore.query(Post.self)
            // result will be of type [Post]
            print("Posts: \(result)")
        } catch let error as DataStoreError {
            print("Error on query() for type Post - \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func queryDataCombine() {
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.query(Post.self)
        }.sink {
            if case let .failure(error) = $0 {
                print("Error on query() for type Post - \(error)")
            }
        }
        receiveValue: { result in
            print("Posts: \(result)")
        }
    }
    
    func queryById() async {
        do {
            let result = try await Amplify.DataStore.query(Post.self, byId: "123")
            // result will be a single object of type Post?
            print("Post: \(result)")
        } catch {
            print("Error on query() for type Post - \(error)")
        }
    }
    
    func predicates() async {
        let p = Post.keys
        do {
            let result = try await Amplify.DataStore.query(Post.self, where: p.rating > 4)
            print("Posts: \(result)")
        } catch let error as DataStoreError {
            print("Error listing posts - \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func predicatesCombine() {
        let p = Post.keys
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.query(Post.self, where: p.rating > 4)
        }.sink {
            if case let .failure(error) = $0 {
                print("Error listing posts - \(error)")
            }
        }
        receiveValue: { result in
            print("Posts: \(result)")
        }
    }
    
    func predicatesMultiple() async {
        let p = Post.keys
        do {
            let result = try await Amplify.DataStore.query(
                Post.self,
                where: p.rating > 4 && p.status == PostStatus.active
            )
            // result of type [Post]
            print("Published posts with rating greater than 4: \(result)")
        } catch let error as DataStoreError {
            print("Error listing posts - \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func predicatesMultipleCombine() {
        let p = Post.keys
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.query(
                Post.self,
                where: p.rating > 4 && p.status == PostStatus.active
            )
        }.sink {
            if case let .failure(error) = $0 {
                print("Error listing posts - \(error)")
            }
        }
        receiveValue: { result in
            print("Published posts with rating greater than 4: \(result)")
        }
    }
    
    func predicatesGt() async throws {
        let p = Post.keys
        try await Amplify.DataStore.query(
            Post.self,
            where: p.rating.gt(4).and(p.status.eq(PostStatus.active))
        )
    }
    
    func predicatesGtCombine() {
        let p = Post.keys
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.query(
                Post.self,
                where: p.rating > 4 && p.status == PostStatus.active
            )
        }.sink { completion in
            print("\(completion)")
        } receiveValue: { posts in
            print("posts \(posts)")
        }
    }
    
    func predicatesOr() async {
        let p = Post.keys
        do {
            let result = try await Amplify.DataStore.query(
                Post.self,
                where: p.rating == nil || p.status == PostStatus.active
            )
            // result of type [Post]
            print("Posts in draft or without rating: \(result)")
        } catch let error as DataStoreError {
            print("Error listing posts - \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func predicatesOrCombine() {
        let p = Post.keys
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.query(
                Post.self,
                where: p.rating == nil || p.status == PostStatus.active
            )
        }.sink {
            if case let .failure(error) = $0 {
                print("Error listing posts - \(error)")
            }
        }
        receiveValue: { result in
            // result of type [Post]
            print("Posts in draft or without rating: \(result)")
        }
    }
    
    func sort() async {
        do {
            let result = try await Amplify.DataStore.query(
                Post.self,
                sort: .ascending(Post.keys.rating))
            print("Posts: \(result)")
        } catch let error as DataStoreError {
            print("Error listing posts - \(error)")
        } catch {
            print("Unexpected error \(error)")
        }
    }
    
    func sortCombine() {
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.query(
                Post.self,
                sort: .ascending(Post.keys.rating))
        }.sink {
            if case let .failure(error) = $0 {
                print("Error listing posts - \(error)")
            }
        }
        receiveValue: { result in
            print("Posts: \(result)")
        }
    }
    
    func sortRating() async {
        do {
            let result = try await Amplify.DataStore.query(
                Post.self,
                sort: .by(
                    .ascending(Post.keys.rating),
                    .descending(Post.keys.title)
                )
            )
            print("Posts: \(result)")
        } catch let error as DataStoreError {
            print("Failed with error \(error)")
        } catch {
            print("Error listing posts - \(error)")
        }
    }
    
    func sortRatingCombine() {
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.query(Post.self,
                                              sort: .ascending(Post.keys.rating))
        }.sink {
            if case let .failure(error) = $0 {
                print("Error listing posts - \(error)")
            }
        }
        receiveValue: { result in
            print("Posts: \(result)")
        }
    }
    
    func pagination() async throws {
        let posts = try await Amplify.DataStore.query(
            Post.self,
            paginate: .page(0, limit: 100))
    }
    
    func paginationCombine() {
        let sink = Amplify.Publisher.create {
            try await Amplify.DataStore.query(
                Post.self,
                paginate: .page(0, limit: 100))
        }.sink { completion in
            print("Completed")
        } receiveValue: { posts in
            print("posts \(posts)")
        }
    }
    
    /*
     Example showing how to observe the model and keep the state updated before performing a save. This uses the
     `@Published` property for views to observe and re-render changes to the model.
     */
    class PostViewModel: ObservableObject {
        @Published var post: Post?
        var subscription: AnyCancellable?

        init() {
        }

        func observe(postId: String) {
            self.subscription = Amplify.Publisher.create(
                Amplify.DataStore.observeQuery(
                    for: Post.self,
                    where: Post.keys.id == postId
                )
            )
            .sink { completion in
                print("Completion event: \(completion)")
            } receiveValue: { snapshot in
                guard let post = snapshot.items.first else {
                    return
                }
                DispatchQueue.main.async {
                    self.post = post
                }
            }
        }

        func updateTitle(_ title: String) async {
            guard var post = post else {
                return
            }
            post.title = title
            do {
                let updatedPost = try await Amplify.DataStore.save(post)
                print("Updated post successfully: \(updatedPost)")
            } catch let error as DataStoreError {
                print("Failed to update post: \(error)")
            } catch {
                print("Unexpected error \(error)")
            }
        }
    }

    struct PostView: View {
        @StateObject var vm = PostViewModel()
        @State private var title = ""
        let postId: String

        init(postId: String) {
            self.postId = postId
        }

        var body: some View {
            VStack {
                Text("Post's current title: \(vm.post?.title ?? "")")
                TextField("Enter new title", text: $title)
                Button("Click to update the title to '\(title)'") {
                    Task { await vm.updateTitle(title) }
                }
            }.onAppear(perform: {
                Task { await vm.observe(postId: postId) }
            })
        }
    }


}

