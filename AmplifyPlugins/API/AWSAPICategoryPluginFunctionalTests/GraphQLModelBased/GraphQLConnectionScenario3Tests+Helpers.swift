//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
@testable import AWSAPICategoryPlugin
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPluginTestCommon

extension GraphQLConnectionScenario3Tests {

    func createPost(id: String = UUID().uuidString, title: String) -> Post3? {
        let post = Post3(id: id, title: title)
        var result: Post3?
        let completeInvoked = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func createComment(id: String = UUID().uuidString, postID: String, content: String) -> Comment3? {
        let comment = Comment3(id: id, postID: postID, content: content)
        var result: Comment3?
        let completeInvoked = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(comment)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let comment):
                    result = comment
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func updatePost(id: String, title: String) -> Post3? {
        var result: Post3?
        let completeInvoked = expectation(description: "request completed")

        let post = Post3(id: id, title: title)
        _ = Amplify.API.mutate(request: .update(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failure(let error):
                print(error)
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func deletePost(post: Post3) -> Post3? {
        var result: Post3?
        let completeInvoked = expectation(description: "request completed")
        _ = Amplify.API.mutate(request: .delete(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failure(let error):
                print(error)
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
