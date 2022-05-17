//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite
@testable import Amplify
@testable import AWSDataStorePlugin

class SQLiteLocalStorageAdapterTests: XCTestCase {
    let databaseName = "TestDatabase"
    
    override class func tearDown() {
        let dbPath = SQLiteLocalStorageAdapter.getDbFilePath(databaseName: "TestDatabase")
        do {
            try FileManager.default.removeItem(atPath: dbPath.path)
        } catch {
            XCTFail("Failed to remove SQLite as part of teardown")
        }
    }
    
    /// - Given: A database name and database path
    /// - When: Creating an instance of SQLiteLocalStorageAdapter
    /// - Then: A database with the specified name is created at the specified path
    func testLocalStorageInitialization() {
        do {
            let dbPath = SQLiteLocalStorageAdapter.getDbFilePath(databaseName: databaseName)
            _ = try SQLiteLocalStorageAdapter(databaseName: databaseName)
            let fileExists = FileManager.default.fileExists(atPath: dbPath.path)
            XCTAssertTrue(fileExists)
        } catch {
            XCTFail("Failed to create SQLiteLocalStorageAdapter: \(error)")
        }
    }
    
    /// - Given: An adapter to the SQLite local database
    /// - When: An insert statement is executed
    /// - Then: A new Event record is added to the database Event table
    func testLocalStorageInsert() {
        do {
            let adapter = try SQLiteLocalStorageAdapter(databaseName: databaseName)
            let countStatement = "SELECT COUNT(*) FROM Event"
            var result = try adapter.executeSqlQuery(countStatement, []).scalar() as! Int64
            XCTAssertTrue(result == 0)
            
            
            let insertStatement = """
                INSERT INTO Event (
                id, attributes, eventType, metrics,
                eventTimestamp, sessionId, sessionStartTime,
                sessionStopTime, timestamp, dirty, retryCount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            let bindings: [Binding] = [1, "", "", "", 100000, 2, 1000000, 1000000, 100000, true, 0]
            _ = try adapter.executeSqlQuery(insertStatement, bindings)
            result = try adapter.executeSqlQuery(countStatement, []).scalar() as! Int64
            XCTAssertTrue(result == 1)
        } catch {
            XCTFail("Failed to create SQLiteLocalStorageAdapter: \(error)")
        }
    }
    
    /// - Given: An adapter to the SQLite local database with an one Event record in the table
    /// - When: An delete statement is executed
    /// - Then: The Event table is empty with 0 records
    func testLocalStorageDelete() {
        do {
            let adapter = try SQLiteLocalStorageAdapter(databaseName: databaseName)
            let insertStatement = """
                INSERT INTO Event (
                id, attributes, eventType, metrics,
                eventTimestamp, sessionId, sessionStartTime,
                sessionStopTime, timestamp, dirty, retryCount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            let bindings: [Binding] = [1, "", "", "", 100000, 2, 1000000, 1000000, 100000, true, 0]
            _ = try adapter.executeSqlQuery(insertStatement, bindings)
            
            let countStatement = "SELECT COUNT(*) FROM Event"
            var result = try adapter.executeSqlQuery(countStatement, []).scalar() as! Int64
            XCTAssertTrue(result == 1)
            
            let deleteStatement = "DELETE FROM Event"
            _ = try adapter.executeSqlQuery(deleteStatement, [])
            result = try adapter.executeSqlQuery(countStatement, []).scalar() as! Int64
            XCTAssertTrue(result == 0)

        } catch {
            XCTFail("Failed to create SQLiteLocalStorageAdapter: \(error)")
        }
    }
    
    /// - Given: An adapter to the SQLite local database with an one Event record that is not dirty
    /// - When: An update statement is executed to update the record as dirty
    /// - Then: The existing event record is updated as dirty
    func testLocalStorageUpdate() {
        do {
            let adapter = try SQLiteLocalStorageAdapter(databaseName: databaseName)
            let insertStatement = """
                INSERT INTO Event (
                id, attributes, eventType, metrics,
                eventTimestamp, sessionId, sessionStartTime,
                sessionStopTime, timestamp, dirty, retryCount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            let bindings: [Binding] = [123, "", "", "", 100000, 2, 1000000, 1000000, 100000, false, 0]
            _ = try adapter.executeSqlQuery(insertStatement, bindings)
            
            let countStatement = "SELECT COUNT(*) FROM Event WHERE dirty = false"
            var result = try adapter.executeSqlQuery(countStatement, []).scalar() as! Int64
            XCTAssertTrue(result == 1)
            
            let updateStatement = """
                UPDATE Event
                SET dirty = ?
                WHERE id = ?
            """
            _ = try adapter.executeSqlQuery(updateStatement, [true, 123])
            result = try adapter.executeSqlQuery(countStatement, []).scalar() as! Int64
            XCTAssertTrue(result == 0)
            
        } catch {
            XCTFail("Failed to create SQLiteLocalStorageAdapter: \(error)")
        }
    }
}
