//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

////
////  StorageEngineTests.swift
////  AWSDataStoreCategoryPluginTests
////
////  Created by Guo, Rui on 6/12/20.
////  Copyright © 2020 Amazon Web Services. All rights reserved.
////
//
//import XCTest
//@testable import Amplify
//@testable import AmplifyTestCommon
//@testable import AWSDataStoreCategoryPlugin
//
//
//class DataStoreConfigurationTests: XCTestCase {
//
//
//
//    func testDatabaseRecreation() throws {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//        let expectation = self.expectation(
//        description: "Database Recreation succeeded")
//
//        let oldVersion = "1234"
//
//        let oldTableStatement = """
//        create table if not exists Post (
//          "id" text primary key not null,
//          "title" text not null,
//          "status" text,
//          "rating" real,
//          "content" text,
//        );
//        """
//
////        StorageEngine(isSyncEnabled: false, dataStoreConfiguration: T##DataStoreConfiguration, newVersion: oldVersion)
//
//        let post = Post(id: "1234")
//
//        Amplify.DataStore.save(post, completion: { _ in })
//
//        let newVersion = "5678"
//
//        let newTableStatement = """
//        create table if not exists Post (
//          "id" text primary key not null,
//          "title" text not null,
//          "status" text,
//          "rating" real,
//          "content" text,
//        );
//        """
//
//        SQLiteStorageEngineAdapter(connection: Connection, dbFilePath: URL?)
////        StorageEngine(isSyncEnabled: false, dataStoreConfiguration: T##DataStoreConfiguration, newVersion: newVersion)
//
//        Amplify.DataStore.query(Post.self, completion: { res in
//            switch result {
//            case .success(let posts):
//                print("Posts retrieved successfully: \(posts)")
//                XCTAssertTrue(posts.isEmpty)
//                expectation.fulfill()
//            case .failure(let error):
//                print("Error retrieving posts \(error)")
//                XCTFail(String(describing: error))
//            }
//        })
//
//        wait(for: [expectation], timeout: 10)
//    }
//
//
//}
