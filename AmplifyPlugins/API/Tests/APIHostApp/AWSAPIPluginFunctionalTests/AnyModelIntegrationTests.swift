//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import AWSAPIPlugin
@testable import APIHostApp
@testable import Amplify
import AWSPluginsCore

class AnyModelIntegrationTests: XCTestCase {
    let networkTimeout: TimeInterval = 180.0

    override func setUp() async throws {
        await Amplify.reset()
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

    override func tearDown() async throws {
        await Amplify.reset()
    }

    func testCreateAsAnyModel() throws {
        let createdAt: Temporal.DateTime = .now()
        let content = "Original post content as of \(createdAt)"
        let originalPost = Post(title: "Post title",
                                content: content,
                                createdAt: createdAt)
        let anyPost = try originalPost.eraseToAnyModel()

        let callbackInvoked = expectation(description: "Callback invoked")
        var responseFromOperation: GraphQLResponse<AnyModel>?
        _ = Amplify.API.mutate(request: .create(anyPost)) { response in
            defer {
                callbackInvoked.fulfill()
            }
            switch response {
            case .success(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failure(let apiError):
                XCTFail("\(apiError)")
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
                case .unknown(let errorDescription, let recoverySuggestion, _):
                    XCTFail("UnknownError: \(errorDescription), \(recoverySuggestion)")
                }
            }
            return
        }

        XCTAssertEqual(modelFromResponse["title"] as? String, originalPost.title)
        XCTAssertEqual(modelFromResponse["content"] as? String, originalPost.content)

    }

    func testUpdateAsAnyModel() throws {
        let createdAt: Temporal.DateTime = .now()
        let content = "Original post content as of \(createdAt)"
        let originalPost = Post(title: "Post title",
                                content: content,
                                createdAt: createdAt)
        let originalAnyPost = try originalPost.eraseToAnyModel()

        let createCallbackInvoked = expectation(description: "Create callback invoked")
        _ = Amplify.API.mutate(request: .create(originalAnyPost)) { _ in
            createCallbackInvoked.fulfill()
        }

        wait(for: [createCallbackInvoked], timeout: networkTimeout)

        let newContent = "Updated post content as of \(Date())"

        var updatedPost = originalPost
        updatedPost.content = newContent
        let updatedAnyPost = try updatedPost.eraseToAnyModel()

        let updateCallbackInvoked = expectation(description: "Update callback invoked")
        var responseFromOperation: GraphQLResponse<AnyModel>?
        _ = Amplify.API.mutate(request: .update(updatedAnyPost)) { response in
            defer {
                updateCallbackInvoked.fulfill()
            }
            switch response {
            case .success(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failure(let apiError):
                XCTFail("\(apiError)")
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
                case .unknown(let errorDescription, let recoverySuggestion, _):
                    XCTFail("UnknownError: \(errorDescription), \(recoverySuggestion)")
                }
            }
            return
        }

        XCTAssertEqual(modelFromResponse["title"] as? String, originalPost.title)
        XCTAssertEqual(modelFromResponse["content"] as? String, updatedPost.content)
    }

    func testDeleteAsAnyModel() throws {
        let createdAt: Temporal.DateTime = .now()
        let content = "Original post content as of \(createdAt)"
        let originalPost = Post(title: "Post title",
                                content: content,
                                createdAt: createdAt)
        let originalAnyPost = try originalPost.eraseToAnyModel()

        let createCallbackInvoked = expectation(description: "Create callback invoked")
        _ = Amplify.API.mutate(request: .create(originalAnyPost)) { _ in
            createCallbackInvoked.fulfill()
        }

        wait(for: [createCallbackInvoked], timeout: networkTimeout)

        let deleteCallbackInvoked = expectation(description: "Delete callback invoked")
        var responseFromOperation: GraphQLResponse<AnyModel>?
        _ = Amplify.API.mutate(request: .delete(originalAnyPost)) { response in
            defer {
                deleteCallbackInvoked.fulfill()
            }
            switch response {
            case .success(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failure(let apiError):
                XCTFail("\(apiError)")
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
                case .unknown(let errorDescription, let recoverySuggestion, _):
                    XCTFail("UnknownError: \(errorDescription), \(recoverySuggestion)")
                }
            }
            return
        }

        XCTAssertEqual(modelFromResponse["title"] as? String, originalPost.title)
    }
}
