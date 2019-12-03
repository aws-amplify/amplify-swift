//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import AWSAPICategoryPlugin

@testable import Amplify
@testable import AmplifyTestCommon

class AnyModelIntegrationTests: XCTestCase {
    let networkTimeout: TimeInterval = 180.0

    override func setUp() {
        Amplify.reset()
        Amplify.Logging.logLevel = .verbose
        ModelRegistry.register(modelType: AmplifyTestCommon.PostNoSync.self)
        ModelRegistry.register(modelType: AmplifyTestCommon.CommentNoSync.self)

        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPIPlugin": [
                GraphQLModelBasedTests.modelBasedGraphQLWithAPIKey: [
                    "endpoint": "https://xxx.appsync-api.us-west-2.amazonaws.com/graphql",
                    "region": "us-west-2",
                    "authorizationType": "API_KEY",
                    "apiKey": "xxxx",
                    "endpointType": "GraphQL"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        do {
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testCreateAsAnyModel() throws {
        let originalPost = PostNoSync(title: "Post title",
                                      content: "Original post content as of \(Date())")
        let anyPost = try originalPost.eraseToAnyModel()

        let callbackInvoked = expectation(description: "Callback invoked")
        var responseFromOperation: GraphQLResponse<AnyModel>?
        _ = Amplify.API.mutate(ofAnyModel: anyPost, type: .create) { response in
            defer {
                callbackInvoked.fulfill()
            }
            switch response {
            case .completed(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failed(let apiError):
                XCTFail("\(apiError)")
            default:
                break
            }
        }

        wait(for: [callbackInvoked], timeout: networkTimeout)

        guard let response = responseFromOperation else {
            XCTAssertNotNil(responseFromOperation)
            return
        }

        guard case .success(let modelFromResponse) = response else {
            switch response {
            case .success:
                break

            case .failure(let error):
                switch error {
                case .error(let errors):
                    XCTFail("errors: \(errors)")
                case .partial(let model, let errors):
                    XCTFail("partial: \(model), \(errors)")
                case .transformationError(let rawResponse, let apiError):
                    XCTFail("transformationError: \(rawResponse), \(apiError)")
                }
            }
            return
        }

        XCTAssertEqual(modelFromResponse["title"] as? String, originalPost.title)
        XCTAssertEqual(modelFromResponse["content"] as? String, originalPost.content)

    }

    func testUpdateAsAnyModel() throws {
        let originalPost = PostNoSync(title: "Post title",
                                      content: "Original post content as of \(Date())")
        let originalAnyPost = try originalPost.eraseToAnyModel()

        let createCallbackInvoked = expectation(description: "Create callback invoked")
        _ = Amplify.API.mutate(ofAnyModel: originalAnyPost, type: .create) { _ in
            createCallbackInvoked.fulfill()
        }

        wait(for: [createCallbackInvoked], timeout: networkTimeout)

        let newContent = "Updated post content as of \(Date())"

        var updatedPost = originalPost
        updatedPost.content = newContent
        let updatedAnyPost = try updatedPost.eraseToAnyModel()

        let updateCallbackInvoked = expectation(description: "Update callback invoked")
        var responseFromOperation: GraphQLResponse<AnyModel>?
        _ = Amplify.API.mutate(ofAnyModel: updatedAnyPost, type: .update) { response in
            defer {
                updateCallbackInvoked.fulfill()
            }
            switch response {
            case .completed(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failed(let apiError):
                XCTFail("\(apiError)")
            default:
                break
            }
        }

        wait(for: [updateCallbackInvoked], timeout: networkTimeout)

        guard let response = responseFromOperation else {
            XCTAssertNotNil(responseFromOperation)
            return
        }

        guard case .success(let modelFromResponse) = response else {
            switch response {
            case .success:
                break
            case .failure(let error):
                switch error {
                case .error(let errors):
                    XCTFail("errors: \(errors)")
                case .partial(let model, let errors):
                    XCTFail("partial: \(model), \(errors)")
                case .transformationError(let rawResponse, let apiError):
                    XCTFail("transformationError: \(rawResponse), \(apiError)")
                }
            }
            return
        }

        XCTAssertEqual(modelFromResponse["title"] as? String, originalPost.title)
        XCTAssertEqual(modelFromResponse["content"] as? String, updatedPost.content)
    }

    func testDeleteAsAnyModel() throws {
        let originalPost = PostNoSync(title: "Post title",
                                      content: "Original post content as of \(Date())")
        let originalAnyPost = try originalPost.eraseToAnyModel()

        let createCallbackInvoked = expectation(description: "Create callback invoked")
        _ = Amplify.API.mutate(ofAnyModel: originalAnyPost, type: .create) { _ in
            createCallbackInvoked.fulfill()
        }

        wait(for: [createCallbackInvoked], timeout: networkTimeout)

        let newContent = "Updated post content as of \(Date())"

        let deleteCallbackInvoked = expectation(description: "Delete callback invoked")
        var responseFromOperation: GraphQLResponse<AnyModel>?
        _ = Amplify.API.mutate(ofAnyModel: originalAnyPost, type: .delete) { response in
            defer {
                deleteCallbackInvoked.fulfill()
            }
            switch response {
            case .completed(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failed(let apiError):
                XCTFail("\(apiError)")
            default:
                break
            }
        }

        wait(for: [deleteCallbackInvoked], timeout: networkTimeout)

        guard let response = responseFromOperation else {
            XCTAssertNotNil(responseFromOperation)
            return
        }

        guard case .success(let modelFromResponse) = response else {
            switch response {
            case .success:
                break
            case .failure(let error):
                switch error {
                case .error(let errors):
                    XCTFail("errors: \(errors)")
                case .partial(let model, let errors):
                    XCTFail("partial: \(model), \(errors)")
                case .transformationError(let rawResponse, let apiError):
                    XCTFail("transformationError: \(rawResponse), \(apiError)")
                }
            }
            return
        }

        XCTAssertEqual(modelFromResponse["title"] as? String, originalPost.title)
    }
}
