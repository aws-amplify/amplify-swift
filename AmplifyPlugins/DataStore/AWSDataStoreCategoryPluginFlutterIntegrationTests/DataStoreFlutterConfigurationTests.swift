//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import XCTest

import AmplifyPlugins
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

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
        let plugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: previousVersion))

        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        let post =  try PostWrapper(title: "title", content: "content")

        plugin.save(post.model, completion: { result in
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
        let pluginReset = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: previousVersion))

        do {
            try Amplify.add(plugin: pluginReset)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        // Query for the previously saved post. Data should be retrieved successfully which indicates that
        // the database file was not deleted after re-configuring Amplify when using the same model registry version
        pluginReset.query(FlutterSerializedModel.self, modelSchema: Post.schema, where: Post.keys.id.eq(post.model.id)) { result in
            switch result {
            case .success(let result):
                guard result.count == 1 else {
                    XCTFail("project query failed")
                    return
                }
                let queriedPost = PostWrapper(model: result[0])
                XCTAssertEqual(queriedPost.idString(), post.idString())
                XCTAssertEqual(queriedPost.title(), post.title())
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("Failed to query post, error: \(error)")
            }
        }

        wait(for: [querySuccess], timeout: TestCommonConstants.networkTimeout)
    }

    func testConfigureWithDifferentSchemaClearsDatabase() throws {

        let previousVersion = "previousVersion"
        let saveSuccess = expectation(description: "Save was successful")
        let plugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: previousVersion))

        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        let post = try PostWrapper(title: "title", content: "content")

        plugin.save(post.model, completion: { result in
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
        let pluginReset = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: "1234"))

        do {

            try Amplify.add(plugin: pluginReset)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        // Query for the previously saved post. Data should not be retrieved successfully which indicates that
        // the database file was deleted after re-configuring Amplify when using a different model registry version
        pluginReset.query(FlutterSerializedModel.self) { result in
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
