//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class DataStoreConfigurationTests: XCTestCase {

    override func setUp() {
        Amplify.reset()
    }

    override func tearDown() {
        Amplify.DataStore.clear(completion: { _ in })
    }

    func testConfigureWithSameSchemaDoesNotDeleteDatabase() throws {

        let previousVersion = "previousVersion"
        let saveSuccess = expectation(description: "Save was successful")

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: previousVersion))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        let post = Post(title: "title", content: "content", createdAt: .now())

        Amplify.DataStore.save(post, completion: { result in
            switch result {
            case .success:
                saveSuccess.fulfill()
            case .failure(let error):
                XCTFail("Error saving post \(error)")
            }
        })

        wait(for: [saveSuccess], timeout: TestCommonConstants.networkTimeout)

        Amplify.reset()

        let querySuccess = expectation(description: "query was successful")

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: previousVersion))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        // Query for the previously saved post. Data should be retrieved successfully which indicates that
        // the database file was not deleted after re-configuring Amplify when using the same model registry version
        Amplify.DataStore.query(Post.self, byId: post.id) { result in
            switch result {
            case .success(let postResult):
                guard let queriedPost = postResult else {
                    XCTFail("could not retrieve post across Amplify re-configure")
                    return
                }
                XCTAssertEqual(queriedPost.title, "title")
                XCTAssertEqual(queriedPost.content, "content")
                XCTAssertEqual(queriedPost.createdAt, post.createdAt)
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("Failed to query post, error: \(error)")
            }
        }

        wait(for: [querySuccess], timeout: TestCommonConstants.networkTimeout)
    }

    func testConfigureWithDifferentSchemaClearsDatabase() throws {

        let prevoisVersion = "previousVersion"
        let saveSuccess = expectation(description: "Save was successful")

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: prevoisVersion))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        let post = Post(title: "title", content: "content", createdAt: .now())

        Amplify.DataStore.save(post, completion: { result in
            switch result {
            case .success:
                saveSuccess.fulfill()
            case .failure(let error):
                XCTFail("Error saving post \(error)")
            }
        })

        wait(for: [saveSuccess], timeout: TestCommonConstants.networkTimeout)

        Amplify.reset()

        let querySuccess = expectation(description: "query was successful")

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: "1234"))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        // Query for the previously saved post. Data should not be retrieved successfully which indicates that
        // the database file was deleted after re-configuring Amplify when using a different model registry version
        Amplify.DataStore.query(Post.self) { result in
            switch result {
            case .success(let postResult):
                XCTAssertTrue(postResult.isEmpty)
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }

        wait(for: [querySuccess], timeout: TestCommonConstants.networkTimeout)
    }
}
