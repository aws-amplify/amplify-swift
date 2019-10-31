//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import AWSMobileClient
import AWSAPICategoryPlugin
@testable import Amplify

class AWSAPICategoryPluginBlogPostCommentGraphQLWithAPIKeyTests: AWSAPICategoryPluginBaseTests {


    /// Given: A valid graphql endpoint with invalid APIKey
    /// When: Call mutate API
    /// Then: The operation completes successfully with no data and error containing Authentication error
    func testAuthError() {
        // use IntegrationTestConfiguration.blogPostCommonGraphQLWithAPIKey
    }

    /// Given: A CreateTodo mutation request
    /// When: Call mutate API
    /// Then: The operation creates a Todo successfully, Todo object is returned, and empty errors array
    func testCreateBlogMutation() {
        let completeInvoked = expectation(description: "request completed")

        let expectedId = UUID().uuidString
        let expectedName = "testCreateBlogMutationName"
        let operation = Amplify.API.mutate(apiName: IntegrationTestConfiguration.blogPostCommonGraphQLWithAPIKey,
                                           document: CreateBlogMutation.document,
                                           variables: CreateBlogMutation.variables(id: expectedId,
                                                                                   name: expectedName),
                                           responseType: CreateBlogMutation.responseType) { (event) in
            switch event {
            case .completed(let graphQLResponse):
                XCTAssertNotNil(graphQLResponse)
                XCTAssertTrue(graphQLResponse.errors.isEmpty)
                guard let blog = graphQLResponse.data else {
                    XCTFail("Missing blog")
                    return
                }

                XCTAssertEqual(blog.id, expectedId)
                XCTAssertEqual(blog.name, expectedName)
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }

    /// Given:
    /// When: Call query API for that Blog
    /// Then: The query operation returns successfully with the Todo object and empty errors
    func testGetBlogQuery() {
        let uuid = "5d501004-748a-49f0-8cde-c6896cd7c0ee"
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"

        let completeInvoked = expectation(description: "request completed")
        let queryOperation = Amplify.API.query(apiName: IntegrationTestConfiguration.blogPostCommonGraphQLWithAPIKey,
                                               document: GetBlogQuery.document,
                                               variables: GetBlogQuery.variables(id: uuid),
                                               responseType: GetBlogQuery.responseType) { (event) in
            switch event {
            case .completed(let graphQLResponse):
                XCTAssertNotNil(graphQLResponse)
                XCTAssertTrue(graphQLResponse.errors.isEmpty)
                guard let blog = graphQLResponse.data else {
                    XCTFail("Missing blog")
                    return
                }

                XCTAssertEqual(blog.id, uuid)
                XCTAssertEqual(blog.name, name)
                print(blog.posts)

                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(queryOperation)
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }

}
