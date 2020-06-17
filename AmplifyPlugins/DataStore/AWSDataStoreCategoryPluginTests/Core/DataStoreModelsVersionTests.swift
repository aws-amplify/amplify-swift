//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class DataStoreModelsVersionTests: XCTestCase {

    func testVersionIsEmpty() {
        let schemaUpdateInvoked = expectation(description: "Version has updated and old database is deleted")

        guard let userDefaults = UserDefaults.init(suiteName: "testVersionIsEmpty") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        let newVersion = "newVersion"

        let mockFileManager = MockFileManager()

        _ = SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                                  databaseName: "database",
                                                                  userDefaults: userDefaults,
                                                                  fileManager: mockFileManager)

        XCTAssertEqual(userDefaults.string(forKey: SQLiteStorageEngineAdapter.dbVersionKey), newVersion)
        schemaUpdateInvoked.fulfill()

        wait(for: [schemaUpdateInvoked], timeout: 10)

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testVersionRemainsSame() {
        let invoked = expectation(description: "Version has updated and old database is deleted")

        guard let userDefaults = UserDefaults.init(suiteName: "testVersionRemainsSame") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        userDefaults.set("previousVersion", forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "previousVersion"

        let mockFileManager = MockFileManager()

        _ = SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                                  databaseName: "database",
                                                                  userDefaults: userDefaults,
                                                                  fileManager: mockFileManager)

        XCTAssertEqual(userDefaults.string(forKey: SQLiteStorageEngineAdapter.dbVersionKey), newVersion)
        invoked.fulfill()

        wait(for: [invoked], timeout: 10)

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testVersionHasChanged() {

        let removeItemInvoked = expectation(description: "Version has updated and old database is deleted")

        guard let userDefaults = UserDefaults.init(suiteName: "testVersionHasChanged") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        userDefaults.set("previousVersion", forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "newVersion"

        let mockFileManager = MockFileManager()
        mockFileManager.removeItem = { url in
            removeItemInvoked.fulfill()
        }

        _ = SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                                  databaseName: "database",
                                                                  userDefaults: userDefaults,
                                                                  fileManager: mockFileManager)

        XCTAssertEqual(userDefaults.string(forKey: SQLiteStorageEngineAdapter.dbVersionKey), newVersion)

        wait(for: [removeItemInvoked], timeout: 10)

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testVersionUpdateFail() {

        let failToremoveItemInvoked = expectation(description: "Should fail to delete old database")

        guard let userDefaults = UserDefaults.init(suiteName: "testVersionHasChanged") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        userDefaults.set("previousVersion", forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "newVersion"

        let mockFileManager = MockFileManager()
        mockFileManager.hasError = true

        let result = SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                                  databaseName: "database",
                                                                  userDefaults: userDefaults,
                                                                  fileManager: mockFileManager)
        if case .failure = result {
            failToremoveItemInvoked.fulfill()
        }

        wait(for: [failToremoveItemInvoked], timeout: 10)

        _ = UserDefaults.removeObject(userDefaults)
    }

}
