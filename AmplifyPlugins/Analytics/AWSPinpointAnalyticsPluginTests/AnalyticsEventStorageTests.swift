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
            
            let insertDirtyEventStatement = """
                INSERT INTO DirtyEvent (
                id, attributes, eventType, metrics,
                eventTimestamp, sessionId, sessionStartTime,
                sessionStopTime, timestamp, dirty, retryCount)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            
            
            let bindings: [Binding] = [1, "attributes", "eventType", "metrics", 1654796845, 1, 1654796847, 1654796848, 1654796845, 0, 0]
            let bindings2: [Binding] = [2, "attributes", "eventType", "metrics", 1654710445, 2, 1654710447, 1654710448, 1654710445, 0, 0]
            let bindings3: [Binding] = [3, "attributes", "eventType", "metrics", 1654624045, 3, 1654624047, 1654624048, 1654624045, 1, 3]
            let bindings4: [Binding] = [4, "attributes", "eventType", "metrics", 1654537645, 4, 1654537647, 1654537648, 1654537645, 1, 3]
            
            _ = try adapter.executeQuery(insertEventStatement, bindings)
            _ = try adapter.executeQuery(insertEventStatement, bindings2)
            _ = try adapter.executeQuery(insertDirtyEventStatement, bindings3)
            _ = try adapter.executeQuery(insertDirtyEventStatement, bindings4)
        } catch {
            XCTFail("Failed to remove SQLite as part of test setup")
        }
    }
    
    override func tearDown() {
        let dbPath = SQLiteLocalStorageAdapter.getDbFilePath(databaseName: "TestDatabase")
        do {
            try FileManager.default.removeItem(atPath: dbPath.path)
        } catch {
            XCTFail("Failed to remove SQLite as part of teardown")
        }
    }
    
    /// - Given: a local storage
    /// - When: disk usage is under the limit
    /// - Then: keep records intact
    func testDiskUsageCheckUnderLimit() {
        do {
            var eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            var dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertTrue(eventcount == 2)
            XCTAssertTrue(dirtyEventcount == 2)
            
            try storage.checkDiskSize(limit: 10000000)
            
            eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertTrue(eventcount == 2)
            XCTAssertTrue(dirtyEventcount == 2)
        } catch {
            XCTFail("Failed to test disk usage under limit")
        }
    }
    
    /// - Given: a local storage
    /// - When: disk usage is over limit
    /// - Then: delete dirty event and oldest event
    func testDiskUsageCheckOverLimit() {
        do {
            var eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            var dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertTrue(eventcount == 2)
            XCTAssertTrue(dirtyEventcount == 2)
            
            try storage.checkDiskSize(limit: 100)
            
            eventcount = try adapter.executeQuery(eventCountStatement, []).scalar() as! Int64
            dirtyEventcount = try adapter.executeQuery(dirtyEventCountStatement, []).scalar() as! Int64
            XCTAssertTrue(eventcount == 1)
            XCTAssertTrue(dirtyEventcount == 0)
        } catch {
            XCTFail("Failed to test disk usage over limit")
        }
    }
}
