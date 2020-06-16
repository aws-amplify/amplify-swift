//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//
//  DataStoreConfigurationTests.swift
//  AWSDataStoreCategoryPluginIntegrationTests
//
//  Created by Guo, Rui on 6/15/20.
//  Copyright © 2020 Amazon Web Services. All rights reserved.
//

import XCTest

import AmplifyPlugins
import AWSMobileClient
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class DataStoreConfigurationTests: XCTestCase {

    func testConfigWithSameSchema() throws {

        let databaseCreationDone = expectation(description: "Old database deleted and new database recreated")

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels())
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure()
            print("Amplify configured with DataStore plugin")
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }

        let time: Temporal.DateTime = .now()
        let post = Post(title: "title", content: "content", createdAt: time)
        let id = post.id

        Amplify.DataStore.save(post, completion: { result in
            switch result {
            case .success:
                print("Post saved successfully!")
                databaseCreationDone.fulfill()
            case .failure(let error):
                print("Error saving post \(error)")
            }
        })
        wait(for: [databaseCreationDone], timeout: 10)

        Amplify.reset()

        let databaseRecreationDone = expectation(description: "Database remains")
        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels())
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure()
            print("Amplify configured with DataStore plugin")
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }

        Amplify.DataStore.query(Post.self, byId: id) { result in
            switch result {
            case .success(let postRes):
                XCTAssertNotNil(postRes)
                XCTAssertEqual(postRes!.id, id)
                XCTAssertEqual(postRes!.title, "title")
                XCTAssertEqual(postRes!.content, "content")
                XCTAssertEqual(postRes!.createdAt, time)
                databaseRecreationDone.fulfill()
            case .failure(let error):
                print("Error retrieving posts \(error)")
                XCTFail("Database is not the same")
            }
        }

        wait(for: [databaseRecreationDone], timeout: 10)

        Amplify.DataStore.clear(completion: { _ in })
    }

    func testConfigWithDifferentSchema() throws {

        let databaseCreationDone = expectation(description: "Database created")

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels())
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure()
            print("Amplify configured with DataStore plugin")
            databaseCreationDone.fulfill()
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }

        wait(for: [databaseCreationDone], timeout: 10)

        let time = Temporal.DateTime.now()
        let post = Post(title: "title", content: "content", createdAt: time)

        let saveToDatabaseDone = expectation(description: "Save data to Database done")
        Amplify.DataStore.save(post, completion: { result in
            switch result {
            case .success:
                print("Post saved successfully!")
                saveToDatabaseDone.fulfill()
            case .failure(let error):
                print("Error saving post \(error)")
            }
        })
        wait(for: [saveToDatabaseDone], timeout: 10)

        ModelRegistry.reset()
        Amplify.reset()

        let databaseRecreationDone = expectation(description: "Old database deleted and new database recreated")

        do {
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: AmplifyModels(version: "1234"))
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure()
            print("Amplify configured with DataStore plugin")
            databaseRecreationDone.fulfill()
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }
        wait(for: [databaseRecreationDone], timeout: 10)

        let databaseRecreationSuccessful = expectation(description: "Old database deleted and new database recreated")

        Amplify.DataStore.query(Post.self) { result in
            switch result {
            case .success(let postRes):
                XCTAssertTrue(postRes.isEmpty)
                databaseRecreationSuccessful.fulfill()
            case .failure(let error):
                print("Error retrieving posts \(error)")
                XCTFail("Database Recreation Failed")
            }
        }
        wait(for: [databaseRecreationSuccessful], timeout: 10)
    }

}
