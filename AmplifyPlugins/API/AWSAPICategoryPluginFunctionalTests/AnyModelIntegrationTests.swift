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
        ModelRegistry.register(modelType: AmplifyTestCommon.Post.self)
        ModelRegistry.register(modelType: AmplifyTestCommon.Comment.self)

        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPIPlugin": [
                "Default": [
                    "endpoint": "https://ldm7yqjfjngrjckbziumz5fxbe.appsync-api.us-west-2.amazonaws.com/graphql",
                    "region": "us-west-2",
                    "authorizationType": "API_KEY",
                    "apiKey": "da2-7jhi34lssbbmjclftlykznhw5m",
                    "endpointType": "GraphQL"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        do {
            try Amplify.add(plugin: AWSAPICategoryPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    // TODO: this test is failing due to provisioned AppSync does not have "_deleted"
    // Variables is created with "_deleted" field and nil value. Service cannot accept it
    func testCreateAsAnyModel() throws {
        let originalPost = Post(title: "Post title",
                                content: "Original post content as of \(Date())")
        let anyPost = try originalPost.eraseToAnyModel()

        let callbackInvoked = expectation(description: "Callback invoked")
        var responseFromOperation: GraphQLResponse<AnyModel>?
        _ = Amplify.API.mutate(of: anyPost, type: .create) { response in
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
        let originalPost = Post(title: "Post title",
                                content: "Original post content as of \(Date())")
        let originalAnyPost = try originalPost.eraseToAnyModel()

        let createCallbackInvoked = expectation(description: "Create callback invoked")
        _ = Amplify.API.mutate(of: originalAnyPost, type: .create) { _ in
            createCallbackInvoked.fulfill()
        }

        wait(for: [createCallbackInvoked], timeout: networkTimeout)

        let newContent = "Updated post content as of \(Date())"

        // Technically we'd pull the version from the sync metadata store, but for this test, we'll hardcode it to 1
        let updatedPost = Post(id: originalPost.id,
                               title: originalPost.title,
                               content: newContent,
                               createdAt: originalPost.createdAt,
                               updatedAt: originalPost.updatedAt,
                               rating: originalPost.rating,
                               draft: originalPost.draft,
                               _version: 1)
        let updatedAnyPost = try updatedPost.eraseToAnyModel()

        let updateCallbackInvoked = expectation(description: "Update callback invoked")
        var responseFromOperation: GraphQLResponse<AnyModel>?
        _ = Amplify.API.mutate(of: updatedAnyPost, type: .update) { response in
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
        XCTFail("Not yet implemented")
    }
}
