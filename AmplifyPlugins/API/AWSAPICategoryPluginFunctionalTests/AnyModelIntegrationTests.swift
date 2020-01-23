//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import AWSAPICategoryPlugin

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPluginTestCommon

class AnyModelIntegrationTests: XCTestCase {
    let networkTimeout: TimeInterval = 180.0

    override func setUp() {
        Amplify.reset()
        Amplify.Logging.logLevel = .verbose

        let plugin = AWSAPIPlugin(modelRegistration: PostCommentModelRegistration())

        do {
            try Amplify.add(plugin: plugin)

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Comment.self)
            ModelRegistry.register(modelType: Post.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testCreateAsAnyModel() throws {

        let originalPost = Post(title: "Post title",
                                content: "Original post content as of \(Date())",
                                createdAt: Date())
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
        let originalPost = Post(title: "Post title",
                                content: "Original post content as of \(Date())",
                                createdAt: Date())
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
        let originalPost = Post(title: "Post title",
                                content: "Original post content as of \(Date())",
                                createdAt: Date())
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
