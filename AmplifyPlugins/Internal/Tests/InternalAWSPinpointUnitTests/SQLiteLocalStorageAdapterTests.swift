//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite
@testable import Amplify
@testable import InternalAWSPinpoint

class SQLiteLocalStorageAdapterTests: XCTestCase {
    private let databaseName = "TestDatabase"
    private var adapter: SQLiteLocalStorageAdapter!
    private var fileManager: MockFileManager!

    override func setUp() {
        fileManager = MockFileManager(fileName: databaseName)
        do {
            adapter = try SQLiteLocalStorageAdapter(databaseName: databaseName, fileManager: fileManager)
            let analyticsEventStorage = AnalyticsEventSQLStorage(dbAdapter: adapter)
            try analyticsEventStorage.initializeStorage()
        } catch {
            XCTFail("Failed to setup SQLiteLocalStorageAdapterTests")
        }
    }

    override func tearDown() {
        fileManager = nil
        adapter = nil
    }

    /// - Given: An adapter to the SQLite local database
    /// - When: An insert statement is executed
    /// - Then: A new Event record is added to the database Event table
    func testLocalStorageInsert() {
        do {
            let countStatement = "SELECT COUNT(*) FROM Event"
            var result = try adapter.executeQuery(countStatement, []).scalar() as! Int64
            XCTAssertEqual(result, 0)

            let insertStatement = """
                INSERT INTO Event (
                id, attributes, eventType, metrics,
                eventTimestamp, sessionId, sessionStartTime,
                sessionStopTime, timestamp, dirty, retryCount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            let bindings: [Binding] = [1, "", "", "", 100000, 2, 1000000, 1000000, 100000, 1, 0]
            _ = try adapter.executeQuery(insertStatement, bindings)
            result = try adapter.executeQuery(countStatement, []).scalar() as! Int64
            XCTAssertEqual(result, 1)
        } catch {
            XCTFail("Failed to create SQLiteLocalStorageAdapter: \(error)")
        }
    }

    /// - Given: An adapter to the SQLite local database with an one Event record in the table
    /// - When: An delete statement is executed
    /// - Then: The Event table is empty with 0 records
    func testLocalStorageDelete() {
        do {
            let insertStatement = """
                INSERT INTO Event (
                id, attributes, eventType, metrics,
                eventTimestamp, sessionId, sessionStartTime,
                sessionStopTime, timestamp, dirty, retryCount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            let bindings: [Binding] = [1, "", "", "", 100000, 2, 1000000, 1000000, 100000, 1, 0]
            _ = try adapter.executeQuery(insertStatement, bindings)

            let countStatement = "SELECT COUNT(*) FROM Event"
            var result = try adapter.executeQuery(countStatement, []).scalar() as! Int64
            XCTAssertTrue(result == 1)

            let deleteStatement = "DELETE FROM Event"
            _ = try adapter.executeQuery(deleteStatement, [])
            result = try adapter.executeQuery(countStatement, []).scalar() as! Int64
            XCTAssertEqual(result, 0)

        } catch {
            XCTFail("Failed to create SQLiteLocalStorageAdapter: \(error)")
        }
    }

    /// - Given: An adapter to the SQLite local database with an one Event record that is not dirty
    /// - When: An update statement is executed to update the record as dirty
    /// - Then: The existing event record is updated as dirty
    func testLocalStorageUpdate() {
        do {
            let insertStatement = """
                INSERT INTO Event (
                id, attributes, eventType, metrics,
                eventTimestamp, sessionId, sessionStartTime,
                sessionStopTime, timestamp, dirty, retryCount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            let bindings: [Binding] = [123, "", "", "", 100000, 2, 1000000, 1000000, 100000, 0, 0]
            _ = try adapter.executeQuery(insertStatement, bindings)

            let countStatement = "SELECT COUNT(*) FROM Event WHERE dirty = false"
            var result = try adapter.executeQuery(countStatement, []).scalar() as! Int64
            XCTAssertEqual(result, 1)

            let updateStatement = """
                UPDATE Event
                SET dirty = ?
                WHERE id = ?
            """
            _ = try adapter.executeQuery(updateStatement, [true, 123])
            result = try adapter.executeQuery(countStatement, []).scalar() as! Int64
            XCTAssertEqual(result, 0)

        } catch {
            XCTFail("Failed to create SQLiteLocalStorageAdapter: \(error)")
        }
    }

    /// - Given: An adapter to the SQLite local database with one record
    /// - When: Calling disk file size
    /// - Then: returns the database file size
    func testLocalStorageDiskUsage() {
        XCTAssertEqual(adapter.diskBytesUsed, fileManager.mockedFileSize)
        XCTAssertEqual(fileManager.fileSizeCount, 1)
    }
}
