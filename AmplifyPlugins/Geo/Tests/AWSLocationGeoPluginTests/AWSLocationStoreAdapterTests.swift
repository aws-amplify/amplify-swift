//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSLocationGeoPlugin

class AWSLocationStoreAdapterTests: XCTestCase {
    
    private var adapter: AWSLocationStoreAdapter!
    private var locationPersistenceBehavior: LocationPersistenceBehavior!
    private var locationFileSystemBehavior: LocationFileSystemBehavior!
    
    override func setUp() {
        locationFileSystemBehavior = MockLocationFileSystem()
        do {
            locationFileSystemBehavior = MockLocationFileSystem()
            locationPersistenceBehavior = try SQLiteLocationPersistenceAdapter(fileSystemBehavior: locationFileSystemBehavior)
            adapter = AWSLocationStoreAdapter(locationPersistenceBehavior: locationPersistenceBehavior)
        } catch {
            XCTFail("Failed to setup SQLiteLocationPersistenceAdapter")
        }
    }

    override func tearDown() {
        adapter = nil
        locationPersistenceBehavior = nil
        locationFileSystemBehavior = nil
    }
    
    /// - Given: A `AWSLocationStoreAdapter` with no locations saved
    /// - When: A `Position` is saved
    /// - Then: The position is successfully saved
    func testInsert() async{
        let position = Position(timeStamp: "123", latitude: 25.0, longitude: 50.0, tracker: "tracker", deviceID: "deviceID")
        do {
            try await adapter.save(position: position)
            let result = try await adapter.queryAll()
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first, position)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A `AWSLocationStoreAdapter` with no locations saved
    /// - When: Multiple `Position` are saved
    /// - Then: All the positions are successfully saved
    func testInsertMany() async {
        let position1 = Position(timeStamp: "123", latitude: 25.0, longitude: 50.0, tracker: "tracker1", deviceID: "deviceID1")
        let position2 = Position(timeStamp: "234", latitude: 30.0, longitude: 40.0, tracker: "tracker2", deviceID: "deviceID2")
        do {
            try await adapter.save(positions: [position1, position2])
            let result = try await adapter.queryAll()
            XCTAssertEqual(result.count, 2)
            XCTAssertTrue(result.contains(position1))
            XCTAssertTrue(result.contains(position2))
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A `AWSLocationStoreAdapter` with a given saved location
    /// - When: A given `Position` is deleted
    /// - Then: The position is successfully deleted
    func testRemove() async {
        let position = Position(timeStamp: "123", latitude: 25.0, longitude: 50.0, tracker: "tracker", deviceID: "deviceID")
        do {
            try await adapter.save(position: position)
            var result = try await adapter.queryAll()
            XCTAssertEqual(result.count, 1)
            XCTAssertEqual(result.first, position)
            
            try await adapter.delete(position: position)
            result = try await adapter.queryAll()
            XCTAssertEqual(result.count, 0)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A `AWSLocationStoreAdapter` with multiple saved locations
    /// - When: Given multiple `Position` are deleted
    /// - Then: All the given positions are successfully deleted
    func testRemoveMany() async {
        let position1 = Position(timeStamp: "123", latitude: 25.0, longitude: 50.0, tracker: "tracker1", deviceID: "deviceID1")
        let position2 = Position(timeStamp: "234", latitude: 30.0, longitude: 40.0, tracker: "tracker2", deviceID: "deviceID2")
        do {
            try await adapter.save(positions: [position1, position2])
            var result = try await adapter.queryAll()
            XCTAssertEqual(result.count, 2)
            XCTAssertTrue(result.contains(position1))
            XCTAssertTrue(result.contains(position2))
            
            try await adapter.delete(positions: [position1, position2])
            result = try await adapter.queryAll()
            XCTAssertEqual(result.count, 0)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A `AWSLocationStoreAdapter` with multiple saved locations
    /// - When: `deleteAll()` is called
    /// - Then: All locations are deleted
    func testDeleteAll() async {
        let position1 = Position(timeStamp: "123", latitude: 25.0, longitude: 50.0, tracker: "tracker1", deviceID: "deviceID1")
        let position2 = Position(timeStamp: "234", latitude: 30.0, longitude: 40.0, tracker: "tracker2", deviceID: "deviceID2")
        let position3 = Position(timeStamp: "456", latitude: 55.0, longitude: 60.0, tracker: "tracker3", deviceID: "deviceID3")
        do {
            try await adapter.save(positions: [position1, position2, position3])
            var result = try await adapter.queryAll()
            XCTAssertEqual(result.count, 3)
            XCTAssertTrue(result.contains(position1))
            XCTAssertTrue(result.contains(position2))
            XCTAssertTrue(result.contains(position3))
            
            try await adapter.deleteAll()
            result = try await adapter.queryAll()
            XCTAssertEqual(result.count, 0)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
    /// - Given: A `AWSLocationStoreAdapter` with multiple saved locations
    /// - When: `queryAll()` is called
    /// - Then: All saved locations are fetched
    func testGetAll() async {
        let position1 = Position(timeStamp: "123", latitude: 25.0, longitude: 50.0, tracker: "tracker1", deviceID: "deviceID1")
        let position2 = Position(timeStamp: "234", latitude: 30.0, longitude: 40.0, tracker: "tracker2", deviceID: "deviceID2")
        let position3 = Position(timeStamp: "456", latitude: 55.0, longitude: 60.0, tracker: "tracker3", deviceID: "deviceID3")
        do {
            try await adapter.save(positions: [position1, position2, position3])
            let result = try await adapter.queryAll()
            XCTAssertEqual(result.count, 3)
            XCTAssertTrue(result.contains(position1))
            XCTAssertTrue(result.contains(position2))
            XCTAssertTrue(result.contains(position3))
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
    
}

