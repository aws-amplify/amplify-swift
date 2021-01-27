//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
@testable import AWSAPICategoryPlugin
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPluginTestCommon

/*
 ```
 # 6 - Blog Post Comment
 type Blog6 @model @searchable {
   id: ID!
   name: String!
   posts: [Post6] @connection(keyName: "byBlog", fields: ["id"])
 }

 type Post6 @model @key(name: "byBlog", fields: ["blogID"]) @searchable {
   id: ID!
   title: String!
   blogID: ID!
   blog: Blog6 @connection(fields: ["blogID"])
   comments: [Comment6] @connection(keyName: "byPost", fields: ["id"])
 }

 type Comment6 @model @key(name: "byPost", fields: ["postID", "content"]) @searchable {
   id: ID!
   postID: ID!
   post: Post6 @connection(fields: ["postID"])
   content: String!
 }
 ```
 */
class GraphQLConnectionScenario6Tests: XCTestCase {

    override func setUp() {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Blog6.self)
            ModelRegistry.register(modelType: Post6.self)
            ModelRegistry.register(modelType: Comment6.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testSearchBlogs() {
        let blogId = UUID().uuidString
        guard let blog1 = createBlog(id: blogId + "1", name: "name"),
              let blog2 = createBlog(id: blogId + "2", name: "name") else {
            XCTFail("Could not create two blogs")
            return
        }

        let searchBlogCompleted = expectation(description: "search blog complete")
        let blog = Blog6.keys
        let predicate = blog.id.evaluate(operator: "matchPhrasePrefix", value: blogId)
        Amplify.API.query(request: .search(Blog6.self, where: predicate, limit: 1)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let blogs):
                    XCTAssertTrue(blogs.hasNextPage())
                    blogs.getNextPage { result in
                        switch result {
                        case .success:
                            searchBlogCompleted.fulfill()
                        case .failure(let error):
                            XCTFail("\(error)")
                        }
                    }

                case .failure(let response): XCTFail("Failed with: \(response)")
                }
            case .failure(let error): XCTFail("\(error)")
            }
        }
        wait(for: [searchBlogCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testGetBlogThenFetchPostsThenFetchComments() {
        guard let blog = createBlog(name: "name"),
              let post1 = createPost(title: "title", blog: blog),
              let post2 = createPost(title: "title", blog: blog),
              let comment1post1 = createComment(post: post1, content: "content"),
              let comment2post1 = createComment(post: post1, content: "content") else {
            XCTFail("Could not create blog, posts, and comments")
            return
        }
        let getBlogCompleted = expectation(description: "get blog complete")
        let fetchPostCompleted = expectation(description: "fetch post complete")
        var resultPosts: List<Post6>?
        Amplify.API.query(request: .get(Blog6.self, byId: blog.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let queriedBlogOptional):
                    guard let queriedBlog = queriedBlogOptional else {
                        XCTFail("Could not get blog")
                        return
                    }
                    XCTAssertEqual(queriedBlog.id, blog.id)
                    getBlogCompleted.fulfill()
                    guard let posts = queriedBlog.posts else {
                        XCTFail("Could not get comments")
                        return
                    }
                    posts.fetch { fetchResults in
                        switch fetchResults {
                        case .success:
                            resultPosts = posts
                            fetchPostCompleted.fulfill()
                        case .failure(let error):
                            XCTFail("Could not fetch posts \(error)")
                        }
                    }
                case .failure(let response): XCTFail("Failed with: \(response)")
                }
            case .failure(let error): XCTFail("\(error)")
            }
        }
        wait(for: [getBlogCompleted, fetchPostCompleted], timeout: TestCommonConstants.networkTimeout)

        let allPosts = getAll(list: resultPosts)
        XCTAssertEqual(allPosts.count, 2)
        guard let fetchedPost = allPosts.first(where: { (post) -> Bool in
            post.id == post1.id
        }), let comments = fetchedPost.comments else {
            XCTFail("Could not set up - failed to get a post and its comments")
            return
        }

        let fetchCommentsCompleted = expectation(description: "fetch post complete")
        var resultComments: List<Comment6>?
        comments.fetch { fetchResults in
            switch fetchResults {
            case .success:
                resultComments = comments
                fetchCommentsCompleted.fulfill()
            case .failure(let error):
                XCTFail("Could not fetch comments \(error)")
            }
        }
        wait(for: [fetchCommentsCompleted], timeout: TestCommonConstants.networkTimeout)
        let allComments = getAll(list: resultComments)
        XCTAssertEqual(allComments.count, 2)
        XCTAssertTrue(allComments.contains(where: { (comment) -> Bool in
            comment.id == comment1post1.id
        }))
        XCTAssertTrue(allComments.contains(where: { (comment) -> Bool in
            comment.id == comment2post1.id
        }))
    }

    func getAll<M>(list: List<M>?) -> [M] {
        guard var list = list else {
            return []
        }
        var results = [M]()
        while list.hasNextPage() {
            let semaphore = DispatchSemaphore(value: 0)
            list.getNextPage { result in
                switch result {
                case .success(let nextList):
                    list = nextList
                    results.append(contentsOf: nextList.elements)
                    semaphore.signal()
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }
            semaphore.wait()
        }
        return list.elements
    }

    func createBlog(id: String = UUID().uuidString, name: String) -> Blog6? {
        let blog = Blog6(id: id, name: name)
        var result: Blog6?
        let requestInvokedSuccessfully = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(blog)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func createPost(id: String = UUID().uuidString, title: String, blog: Blog6) -> Post6? {
        let post = Post6(id: id, title: title, blog: blog)
        var result: Post6?
        let requestInvokedSuccessfully = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func createComment(id: String = UUID().uuidString, post: Post6, content: String) -> Comment6? {
        let comment = Comment6(id: id, post: post, content: content)
        var result: Comment6?
        let requestInvokedSuccessfully = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(comment)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let comment):
                    result = comment
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
