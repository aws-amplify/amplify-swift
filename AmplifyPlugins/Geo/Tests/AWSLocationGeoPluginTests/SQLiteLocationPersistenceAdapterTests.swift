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
    func testInsert() {
        let position = Position(timeStamp: "123", latitude: 25.0, longitude: 50.0, tracker: "tracker")
        do {
            try adapter.insert(position: position)
            let result = try adapter.getAll()
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first, position)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A SQLite adapter to location database with no locations saved
    /// - When: Multiple `Position` are inserted
    /// - Then: All the positions are successfully saved into the database
    func testInsertMany() {
        let position1 = Position(timeStamp: "123", latitude: 25.0, longitude: 50.0, tracker: "tracker1")
        let position2 = Position(timeStamp: "234", latitude: 30.0, longitude: 40.0, tracker: "tracker2")
        do {
            try adapter.insert(positions: [position1, position2])
            let result = try adapter.getAll()
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
    func testRemove() {
        let position = Position(timeStamp: "123", latitude: 25.0, longitude: 50.0, tracker: "tracker")
        do {
            try adapter.insert(position: position)
            var result = try adapter.getAll()
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first, position)
            
            try adapter.remove(position: position)
            result = try adapter.getAll()
            XCTAssertEqual(result.count, 0)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A SQLite adapter to location database with multiple saved locations
    /// - When: Given multiple `Position` are removed
    /// - Then: All the given positions are successfully removed from the database
    func testRemoveMany() {
        let position1 = Position(timeStamp: "123", latitude: 25.0, longitude: 50.0, tracker: "tracker1")
        let position2 = Position(timeStamp: "234", latitude: 30.0, longitude: 40.0, tracker: "tracker2")
        do {
            try adapter.insert(positions: [position1, position2])
            var result = try adapter.getAll()
            XCTAssertEqual(result.count, 2)
            XCTAssertTrue(result.contains(position1))
            XCTAssertTrue(result.contains(position2))
            
            try adapter.remove(positions: [position1, position2])
            result = try adapter.getAll()
            XCTAssertEqual(result.count, 0)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A SQLite adapter to location database with multiple saved locations
    /// - When: `removeAll()` is called
    /// - Then: All locations in the database are removed
    func testDeleteAll() {
        let position1 = Position(timeStamp: "123", latitude: 25.0, longitude: 50.0, tracker: "tracker1")
        let position2 = Position(timeStamp: "234", latitude: 30.0, longitude: 40.0, tracker: "tracker2")
        let position3 = Position(timeStamp: "456", latitude: 55.0, longitude: 60.0, tracker: "tracker3")
        do {
            try adapter.insert(positions: [position1, position2, position3])
            var result = try adapter.getAll()
            XCTAssertEqual(result.count, 3)
            XCTAssertTrue(result.contains(position1))
            XCTAssertTrue(result.contains(position2))
            XCTAssertTrue(result.contains(position3))
            
            try adapter.removeAll()
            result = try adapter.getAll()
            XCTAssertEqual(result.count, 0)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A SQLite adapter to location database with multiple saved locations
    /// - When: `getAll()` is called
    /// - Then: All saved locations are fetched
    func testGetAll() {
        let position1 = Position(timeStamp: "123", latitude: 25.0, longitude: 50.0, tracker: "tracker1")
        let position2 = Position(timeStamp: "234", latitude: 30.0, longitude: 40.0, tracker: "tracker2")
        let position3 = Position(timeStamp: "456", latitude: 55.0, longitude: 60.0, tracker: "tracker3")
        do {
            try adapter.insert(positions: [position1, position2, position3])
            let result = try adapter.getAll()
            XCTAssertEqual(result.count, 3)
            XCTAssertTrue(result.contains(position1))
            XCTAssertTrue(result.contains(position2))
            XCTAssertTrue(result.contains(position3))
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
}
