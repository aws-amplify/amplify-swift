//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSPluginsCore

@testable import Amplify
@testable import AWSDataStorePlugin

class DataStoreConfigurationTests: XCTestCase {

    override func tearDown() async throws {
        try await Amplify.DataStore.clear()
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
    }

    func testConfigureWithSameSchemaDoesNotDeleteDatabase() async throws {
        let previousVersion = "previousVersion"
        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: previousVersion))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        let post = Post(title: "title", content: "content", createdAt: .now())

        _ = try await Amplify.DataStore.save(post)

        await Amplify.reset()

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: previousVersion))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        // Query for the previously saved post. Data should be retrieved successfully which indicates that
        // the database file was not deleted after re-configuring Amplify when using the same model registry version
        let postResult = try await Amplify.DataStore.query(Post.self, byId: post.id)
        guard let queriedPost = postResult else {
            XCTFail("could not retrieve post across Amplify re-configure")
            return
        }
        XCTAssertEqual(queriedPost.title, "title")
        XCTAssertEqual(queriedPost.content, "content")
        XCTAssertEqual(queriedPost.createdAt, post.createdAt)
    }

    func testConfigureWithDifferentSchemaClearsDatabase() async throws {
        let prevoisVersion = "previousVersion"

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: prevoisVersion))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        let post = Post(title: "title", content: "content", createdAt: .now())
        _ = try await Amplify.DataStore.save(post)

        await Amplify.reset()

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: "1234"))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(AmplifyConfiguration(dataStore: nil))
        } catch {
            XCTFail("Failed to initialize Amplify with \(error)")
        }

        // Query for the previously saved post. Data should not be retrieved successfully which indicates that
        // the database file was deleted after re-configuring Amplify when using a different model registry version
        let postResult = try await Amplify.DataStore.query(Post.self)
        XCTAssertTrue(postResult.isEmpty)
    }
}
