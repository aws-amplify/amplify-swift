//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import AWSAPICategoryPlugin
@testable import Amplify
@testable import AWSAPICategoryPluginTestCommon
@testable import AmplifyTestCommon

// These test cover the more complex scenarios, compared to the Todo graphQL endpoint
class BlogPostCommentGraphQLWithAPIKeyTests: XCTestCase {

    /*
     These are the instructions to set up the `blogPostCommonGraphQLWithAPIKey`. Same as `todoGraphQLWithAPIKey`
     except with the Blog Post and Comment graphQL schema

     2. Add api `amplify add api`
         * What best describes your project: `One-to-many relationship (e.g., “Blogs” with “Posts” and “Comments”)`

     3. `amplify push`
        * Enter maximum statement depth [increase from default if your schema is deeply nested] `3`

     */
    static let blogPostGraphQLWithAPIKey = "blogPostCommentGraphQLWithAPIKey"

    /*
     Using the same values as `blogPostCommonGraphQLWithAPIKey` except the API key is replaced with an invalid one.
     */
    static let blogPostGraphQLWithInvalidAPIKey = "blogPostCommentGraphQLWithInvalidAPIKey"

    override func setUp() {
        Amplify.reset()
        let plugin = AWSAPIPlugin()

        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPIPlugin": [
                BlogPostCommentGraphQLWithAPIKeyTests.blogPostGraphQLWithAPIKey: [
                    "endpoint": "https://xxx.appsync-api.us-east-1.amazonaws.com/graphql",
                    "region": "us-east-1",
                    "authorizationType": "API_KEY",
                    "apiKey": "da2-xxx",
                    "endpointType": "GraphQL"
                ],
                BlogPostCommentGraphQLWithAPIKeyTests.blogPostGraphQLWithInvalidAPIKey: [
                    "endpoint": "https://xxx.appsync-api.us-east-1.amazonaws.com/graphql",
                    "region": "us-east-1",
                    "authorizationType": "API_KEY",
                    "apiKey": "da2-invalidAPIKey",
                    "endpointType": "GraphQL"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    /// Given: A valid graphql endpoint with invalid API Key
    /// When: Call mutate API
    /// Then: The operation fails with HttpStatus error containing Authentication error
    func testCreateBlogMutationWithInvalidAPIKey() {
        let failedInvoked = expectation(description: "request failed")
        let expectedId = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let request = GraphQLRequest(apiName: BlogPostCommentGraphQLWithAPIKeyTests.blogPostGraphQLWithInvalidAPIKey,
                                     document: CreateBlogMutation.document,
                                     variables: CreateBlogMutation.variables(id: expectedId,
                                                                             name: testMethodName),
                                     responseType: CreateBlogMutation.Data.self)
        let operation = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let graphQLResponse):
                XCTFail("Unexpected .completed event: \(graphQLResponse)")
            case .failed(let error):
                guard case let .httpStatusError(statusCode, httpURLResponse) = error else {
                    XCTFail("Should be Http Status error")
                    return
                }

                XCTAssertEqual(statusCode, 401)
                failedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: Create a blog
    /// When: Call GetBlog query API for that blog, with responseType String
    /// Then: The successful query operation returns graphQLResponse.data as String, and no errors, and decodes to Blog
    func testGetBlogQueryAsStringAndDecode() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"

        guard let blog = createBlog(id: uuid, name: name) else {
            XCTFail("Failed to set up test")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        let request = GraphQLRequest(apiName: BlogPostCommentGraphQLWithAPIKeyTests.blogPostGraphQLWithAPIKey,
                                     document: GetBlogQuery.document,
                                     variables: GetBlogQuery.variables(id: blog.id),
                                     responseType: String.self)
        let queryOperation = Amplify.API.query(request: request) { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(dataString) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }

                do {
                    guard let serializedBlog = dataString.data(using: .utf8) else {
                        XCTFail("Could not get data from string result")
                        return
                    }
                    let blogObject = try JSONDecoder().decode(GetBlogQuery.Data.self, from: serializedBlog)
                    guard let blog = blogObject.getBlog else {
                        XCTFail("Failed to deserlize to blog")
                        return
                    }
                    XCTAssertNotNil(blog)
                    XCTAssertEqual(blog.id, uuid)
                    XCTAssertEqual(blog.name, name)
                    XCTAssertTrue(blog.posts!.items.isEmpty)
                    XCTAssertNil(blog.posts!.nextToken)
                } catch {
                    XCTFail("Failed to deserialize blog as JSONValue into Blog type")
                }

                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(queryOperation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: Create a blog, a post on that blog, a comment on that post.
    /// When: Call GetBlog query API for the blog
    /// Then: The query operation returns successfully with no errors and the Blog contains the Post and the Comment
    func testGetBlogQueryWithPostAndComment() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let title = testMethodName + "Title"
        let content = testMethodName + "Content"

        guard let blog = createBlog(id: uuid, name: name) else {
            XCTFail("Failed to set up test")
            return
        }
        guard let post = createPost(postBlogId: blog.id, title: title) else {
            XCTFail("Failed to set up test")
            return
        }
        guard let comment = createComment(commentPostId: post.id, content: content) else {
            XCTFail("Failed to set up test")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        let request = GraphQLRequest(apiName: BlogPostCommentGraphQLWithAPIKeyTests.blogPostGraphQLWithAPIKey,
                                     document: GetBlogQuery.document,
                                     variables: GetBlogQuery.variables(id: blog.id),
                                     responseType: GetBlogQuery.Data.self)
        let queryOperation = Amplify.API.query(request: request) { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }

                guard let blog = data.getBlog else {
                    XCTFail("Missing blog")
                    return
                }

                XCTAssertEqual(blog.id, uuid)
                XCTAssertEqual(blog.name, name)
                XCTAssertEqual(blog.posts!.items!.first!.id, post.id)
                XCTAssertEqual(blog.posts!.items!.first!.title, post.title)
                XCTAssertEqual(blog.posts!.items!.first!.comments?.items?.first?.id, comment.id)
                XCTAssertEqual(blog.posts!.items!.first!.comments?.items?.first?.content, comment.content)
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(queryOperation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    // MARK: Common functionality

    func createBlog(id: String, name: String) -> Blog? {
        var blog: Blog?
        let completeInvoked = expectation(description: "request completed")
        let request = GraphQLRequest(apiName: BlogPostCommentGraphQLWithAPIKeyTests.blogPostGraphQLWithAPIKey,
                                     document: CreateBlogMutation.document,
                                     variables: CreateBlogMutation.variables(id: id, name: name),
                                     responseType: CreateBlogMutation.Data.self)
        let operation = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let createBlog = data.createBlog else {
                    XCTFail("Missing blog")
                    return
                }
                blog = createBlog
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        return blog
    }

    func createPost(postBlogId: String, title: String) -> AWSAPICategoryPluginTestCommon.Post? {
        var post: AWSAPICategoryPluginTestCommon.Post?
        let completeInvoked = expectation(description: "request completed")
        let request = GraphQLRequest(apiName: BlogPostCommentGraphQLWithAPIKeyTests.blogPostGraphQLWithAPIKey,
                                     document: CreatePostMutation.document,
                                     variables: CreatePostMutation.variables(postBlogId: postBlogId,
                                                                             title: title),
                                     responseType: CreatePostMutation.Data.self)
        let operation = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let createPost = data.createPost else {
                    XCTFail("Missing post")
                    return
                }
                post = createPost
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        return post
    }

    func createComment(commentPostId: String, content: String) -> AWSAPICategoryPluginTestCommon.Comment? {
        var comment: AWSAPICategoryPluginTestCommon.Comment?
        let completeInvoked = expectation(description: "request completed")
        let request = GraphQLRequest(apiName: BlogPostCommentGraphQLWithAPIKeyTests.blogPostGraphQLWithAPIKey,
                                     document: CreateCommentMutation.document,
                                     variables: CreateCommentMutation.variables(commentPostId: commentPostId,
                                                                                content: content),
                                     responseType: CreateCommentMutation.Data.self)
        let operation = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let createComment = data.createComment else {
                    XCTFail("Missing comment")
                    return
                }

                comment = createComment
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        return comment
    }

}
