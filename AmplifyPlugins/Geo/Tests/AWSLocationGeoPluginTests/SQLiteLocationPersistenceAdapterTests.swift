//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSLocationGeoPlugin

class SQLiteLocationPersistenceAdapterTests: XCTestCase {
    
    private var adapter: SQLiteLocationPersistenceAdapter!
    private var locationFileSystemBehavior: LocationFileSystemBehavior!

    override func setUp() {
        locationFileSystemBehavior = MockLocationFileSystem()
        do {
            adapter = try SQLiteLocationPersistenceAdapter(fileSystemBehavior: locationFileSystemBehavior)
        } catch {
            XCTFail("Failed to setup SQLiteLocationPersistenceAdapter")
        }
    }

    override func tearDown() {
        adapter = nil
        locationFileSystemBehavior = nil
    }
    
    /// - Given: A SQLite adapter to location database with no locations saved
    /// - When: A `Position` is inserted
    /// - Then: The position is successfully saved into the database
    func testInsert() async {
        let position = PositionInternal(timeStamp: Date(), latitude: 25.0, longitude: 50.0, tracker: "tracker", deviceID: "deviceID")
        do {
            try await adapter.insert(position: position)
            let result = try await adapter.getAll()
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first, position)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A SQLite adapter to location database with no locations saved
    /// - When: Multiple `Position` are inserted
    /// - Then: All the positions are successfully saved into the database
    func testInsertMany() async {
        let position1 = PositionInternal(timeStamp: Date(), latitude: 25.0, longitude: 50.0, tracker: "tracker1", deviceID: "deviceID1")
        let position2 = PositionInternal(timeStamp: Date(), latitude: 30.0, longitude: 40.0, tracker: "tracker2", deviceID: "deviceID2")
        do {
            try await adapter.insert(positions: [position1, position2])
            let result = try await adapter.getAll()
            XCTAssertEqual(result.count, 2)
            XCTAssertTrue(result.contains(position1))
            XCTAssertTrue(result.contains(position2))
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A SQLite adapter to location database with a given saved location
    /// - When: A given `Position` is removed
    /// - Then: The position is successfully removed from the database
    func testRemove() async {
        let position = PositionInternal(timeStamp: Date(), latitude: 25.0, longitude: 50.0, tracker: "tracker", deviceID: "deviceID")
        do {
            try await adapter.insert(position: position)
            var result = try await adapter.getAll()
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first, position)
            
            try await adapter.remove(position: position)
            result = try await adapter.getAll()
            XCTAssertEqual(result.count, 0)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A SQLite adapter to location database with multiple saved locations
    /// - When: Given multiple `Position` are removed
    /// - Then: All the given positions are successfully removed from the database
    func testRemoveMany() async {
        let position1 = PositionInternal(timeStamp: Date(), latitude: 25.0, longitude: 50.0, tracker: "tracker1", deviceID: "deviceID1")
        let position2 = PositionInternal(timeStamp: Date(), latitude: 30.0, longitude: 40.0, tracker: "tracker2", deviceID: "deviceID2")
        do {
            try await adapter.insert(positions: [position1, position2])
            var result = try await adapter.getAll()
            XCTAssertEqual(result.count, 2)
            XCTAssertTrue(result.contains(position1))
            XCTAssertTrue(result.contains(position2))
            
            try await adapter.remove(positions: [position1, position2])
            result = try await adapter.getAll()
            XCTAssertEqual(result.count, 0)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A SQLite adapter to location database with multiple saved locations
    /// - When: `removeAll()` is called
    /// - Then: All locations in the database are removed
    func testDeleteAll() async {
        let position1 = PositionInternal(timeStamp: Date(), latitude: 25.0, longitude: 50.0, tracker: "tracker1", deviceID: "deviceID1")
        let position2 = PositionInternal(timeStamp: Date(), latitude: 30.0, longitude: 40.0, tracker: "tracker2", deviceID: "deviceID2")
        let position3 = PositionInternal(timeStamp: Date(), latitude: 55.0, longitude: 60.0, tracker: "tracker3", deviceID: "deviceID3")
        do {
            try await adapter.insert(positions: [position1, position2, position3])
            var result = try await adapter.getAll()
            XCTAssertEqual(result.count, 3)
            XCTAssertTrue(result.contains(position1))
            XCTAssertTrue(result.contains(position2))
            XCTAssertTrue(result.contains(position3))
            
            try await adapter.removeAll()
            result = try await adapter.getAll()
            XCTAssertEqual(result.count, 0)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A SQLite adapter to location database with multiple saved locations
    /// - When: `getAll()` is called
    /// - Then: All saved locations are fetched
    func testGetAll() async {
        let position1 = PositionInternal(timeStamp: Date(), latitude: 25.0, longitude: 50.0, tracker: "tracker1", deviceID: "deviceID1")
        let position2 = PositionInternal(timeStamp: Date(), latitude: 30.0, longitude: 40.0, tracker: "tracker2", deviceID: "deviceID2")
        let position3 = PositionInternal(timeStamp: Date(), latitude: 55.0, longitude: 60.0, tracker: "tracker3", deviceID: "deviceID3")
        do {
            try await adapter.insert(positions: [position1, position2, position3])
            let result = try await adapter.getAll()
            XCTAssertEqual(result.count, 3)
            XCTAssertTrue(result.contains(position1))
            XCTAssertTrue(result.contains(position2))
            XCTAssertTrue(result.contains(position3))
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
}
