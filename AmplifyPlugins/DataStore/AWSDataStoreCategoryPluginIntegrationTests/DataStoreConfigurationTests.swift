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
            let dataStoreConfiguration = AmplifyConfiguration(dataStore: nil)
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: prevoisVersion))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(dataStoreConfiguration)
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
            try Amplify.configure()
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

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
            let dataStoreConfiguration = AmplifyConfiguration(dataStore: nil)
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: prevoisVersion))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(dataStoreConfiguration)
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        let time = Temporal.DateTime.now()
        let post = Post(title: "title", content: "content", createdAt: time)

        Amplify.DataStore.save(post, completion: { result in
            switch result {
            case .success:
                saveSuccess.fulfill()
            case .failure(let error):
                XCTFail("Error saving post \(error)")
            }
        })
        wait(for: [saveSuccess], timeout: TestCommonConstants.networkTimeout)

        ModelRegistry.reset()
        Amplify.reset()

        let databaseRecreationDone = expectation(description: "Old database deleted and new database recreated")

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: "1234"))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure()
            databaseRecreationDone.fulfill()
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }
        wait(for: [databaseRecreationDone], timeout: 10)

        let querySuccess = expectation(description: "Old database deleted and new database recreated")

        Amplify.DataStore.query(Post.self) { result in
            switch result {
            case .success(let postRes):
                XCTAssertTrue(postRes.isEmpty)
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("Database Recreation Failed")
            }
        }
        wait(for: [querySuccess], timeout: TestCommonConstants.networkTimeout)

        Amplify.DataStore.clear(completion: { _ in })
    }

}
