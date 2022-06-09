//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite
@testable import Amplify
@testable import AWSPinpointAnalyticsPlugin

class AnalyticsEventStorageTests: XCTestCase {
    let databaseName = "TestDatabase"
    var adapter: SQLStorageProtocol!
    let eventCountStatement = "SELECT COUNT(*) FROM Event"
    let dirtyEventCountStatement = "SELECT COUNT(*) FROM DirtyEvent"
    var storage: AnalyticsEventStorage!
    
    override func setUp() {
        do {
            adapter = try SQLiteLocalStorageAdapter(databaseName: databaseName)
            storage = AnalyticsEventSQLStorage(dbAdapter: adapter)
            try storage.initializeStorage()
            
            let insertEventStatement = """
                INSERT INTO Event (
                id, attributes, eventType, metrics,
                eventTimestamp, sessionId, sessionStartTime,
                sessionStopTime, timestamp, dirty, retryCount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            let bindings: [Binding] = [1, "", "", "", 100000, 2, 1000000, 1000000, 100000, true, 0]
            
            let insertDirtyEventStatement = """
                INSERT INTO DirtyEvent (
                id, attributes, eventType, metrics,
                eventTimestamp, sessionId, sessionStartTime,
                sessionStopTime, timestamp, dirty, retryCount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            _ = try adapter.executeQuery(insertEventStatement, bindings)
            _ = try adapter.executeQuery(insertDirtyEventStatement, bindings)
        } catch {
            XCTFail("Failed to remove SQLite as part of test setup")
        }
    }
    
    override class func tearDown() {
        let dbPath = SQLiteLocalStorageAdapter.getDbFilePath(databaseName: "TestDatabase")
        do {
            try FileManager.default.removeItem(atPath: dbPath.path)
        } catch {
            XCTFail("Failed to remove SQLite as part of teardown")
        }
    }
    
    /// - Given: a local storage
    /// - When: disk usage is over limit
    /// - Then:
    func testDiskUsageCheckOverLimit() {
        do {
            var eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            var dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertTrue(eventcount == 1)
            XCTAssertTrue(dirtyEventcount == 1)
            
            try storage.checkDiskSize(limit: 100)
            
            eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertTrue(eventcount == 0)
            XCTAssertTrue(dirtyEventcount == 0)
        } catch {
            XCTFail("Failed to test disk usage over limit")
        }
    }
    
    /// - Given: a local storage
    /// - When: disk usage is under the limit
    /// - Then: storage
    func testDiskUsageCheckUnderLimit() {
        do {
            var eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            var dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertTrue(eventcount == 1)
            XCTAssertTrue(dirtyEventcount == 1)
            
            try storage.checkDiskSize(limit: 10000000)
            
            eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertTrue(eventcount == 1)
            XCTAssertTrue(dirtyEventcount == 1)
        } catch {
            XCTFail("Failed to test disk usage under limit")
        }
    }
}
