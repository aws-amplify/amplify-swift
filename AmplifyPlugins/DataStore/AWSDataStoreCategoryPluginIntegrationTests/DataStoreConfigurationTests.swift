//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSMobileClient
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class DataStoreConfigurationTests: XCTestCase {

    func testConfigureWithSameSchemaDoesNotDeleteDatabase() throws {
        Amplify.reset()

        let prevoisVersion = "123"

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

        let querySuccess = expectation(description: "Database remains")

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: prevoisVersion))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        // Here trying to query the saved data from above, because if the schema hasn't been changed that the database and saved data should persist.
        Amplify.DataStore.query(Post.self, byId: post.id) { result in
            switch result {
            case .success(let postOptional):
                querySuccess.fulfill()
                guard let queriedPost = postOptional else {
                    XCTFail("could not retrieve post across Amplify re-configure")
                    return
                }
                XCTAssertEqual(queriedPost.title, "title")
                XCTAssertEqual(queriedPost.content, "content")
                XCTAssertEqual(queriedPost.createdAt, post.createdAt)
            case .failure(let error):
                XCTFail("Database is not the same, this shouldn't happen, error: \(error)")
            }
        }

        wait(for: [querySuccess], timeout: TestCommonConstants.networkTimeout)

        Amplify.DataStore.clear(completion: { _ in })
    }

    func testConfigWithDifferentSchema() throws {
        Amplify.reset()

        let prevoisVersion = "123"

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

        let querySuccess = expectation(description: "Old database deleted and new database recreated")

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: "1234"))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        Amplify.DataStore.query(Post.self) { result in
            switch result {
            case .success(let postRes):
                XCTAssertTrue(postRes.isEmpty)
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("Database Recreation Failed due to \(error)")
            }
        }

        wait(for: [querySuccess], timeout: TestCommonConstants.networkTimeout)

        Amplify.DataStore.clear(completion: { _ in })
    }

}
