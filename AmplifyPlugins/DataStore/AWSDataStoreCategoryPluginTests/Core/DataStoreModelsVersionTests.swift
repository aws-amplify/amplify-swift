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

    func testVersionInUserDefaultsIsEmpty() {
        let schemaUpdateInvoked = expectation(description: "Version has updated and old database is deleted")

        guard let userDefaults = UserDefaults.init(suiteName: "testVersionIsEmpty") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        let newVersion = "newVersion"

        let mockFileManager = MockFileManager()
        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                             dbFilePath: URL(string: "dbFilePath")!,
                                                             userDefaults: userDefaults,
                                                             fileManager: mockFileManager)
        } catch {
             XCTFail("Test has failed due to\(error)")
        }

        XCTAssertEqual(userDefaults.string(forKey: SQLiteStorageEngineAdapter.dbVersionKey), newVersion)
        schemaUpdateInvoked.fulfill()

        wait(for: [schemaUpdateInvoked], timeout: 10)

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testVersionInUserDefaultsRemainsSame() {
        let invoked = expectation(description: "Version remains the same")

        guard let userDefaults = UserDefaults.init(suiteName: "testVersionInUserDefaultsRemainsSame") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        userDefaults.set("previousVersion", forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "previousVersion"

        let mockFileManager = MockFileManager()
        mockFileManager.fileExists = true

        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                         dbFilePath: URL(string: "dbFilePath")!,
                                                         userDefaults: userDefaults,
                                                         fileManager: mockFileManager)
        } catch {
            XCTFail("Test has failed due to\(error)")
        }

        XCTAssertEqual(userDefaults.string(forKey: SQLiteStorageEngineAdapter.dbVersionKey), newVersion)
        invoked.fulfill()

        wait(for: [invoked], timeout: 10)

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testVersionInUserDefaultsRemainsSameButFileDoesNotExist() {
        let invoked = expectation(description: "Version remains the same")

        guard let userDefaults = UserDefaults.init(suiteName: "VersionRemainsSameButFileDoesNotExist") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        userDefaults.set("previousVersion", forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "previousVersion"

        let mockFileManager = MockFileManager()

        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                         dbFilePath: URL(string: "dbFilePath")!,
                                                         userDefaults: userDefaults,
                                                         fileManager: mockFileManager)
        } catch {
            XCTFail("Test has failed due to\(error)")
        }

        XCTAssertEqual(userDefaults.string(forKey: SQLiteStorageEngineAdapter.dbVersionKey), newVersion)
        invoked.fulfill()

        wait(for: [invoked], timeout: 10)

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testVersionInUserDefaultsHasChanged() {

        let removeItemInvoked = expectation(description: "Version has updated and old database is deleted")

        guard let userDefaults = UserDefaults.init(suiteName: "testVersionHasChanged") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        userDefaults.set("previousVersion", forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "newVersion"

        let mockFileManager = MockFileManager()
        mockFileManager.fileExists = true
        mockFileManager.removeItem = { url in
            removeItemInvoked.fulfill()
        }

        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                             dbFilePath: URL(string: "dbFilePath")!,
                                                             userDefaults: userDefaults,
                                                             fileManager: mockFileManager)
        } catch {
             XCTFail("Test has failed due to\(error)")
        }

        wait(for: [removeItemInvoked], timeout: 10)

        _ = UserDefaults.removeObject(userDefaults)
    }

    func testVersionInUserDefaultsUpdateFail() {

        let failToremoveItemInvoked = expectation(description: "Should fail to delete old database")

        guard let userDefaults = UserDefaults.init(suiteName: "testVersionHasChanged") else {
            XCTFail("Could not create a UserDafult with this suite name")
            return
        }

        userDefaults.set("previousVersion", forKey: SQLiteStorageEngineAdapter.dbVersionKey)

        let newVersion = "newVersion"

        let mockFileManager = MockFileManager()
        mockFileManager.hasError = true
        mockFileManager.fileExists = true

        do {
            try SQLiteStorageEngineAdapter.clearIfNewVersion(version: newVersion,
                                                             dbFilePath: URL(string: "dbFilePath")!,
                                                             userDefaults: userDefaults,
                                                             fileManager: mockFileManager)
        } catch {
            failToremoveItemInvoked.fulfill()
        }

        wait(for: [failToremoveItemInvoked], timeout: 10)

        _ = UserDefaults.removeObject(userDefaults)
    }

}
