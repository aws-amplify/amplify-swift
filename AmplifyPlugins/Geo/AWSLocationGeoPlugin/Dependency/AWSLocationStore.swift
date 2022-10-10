//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import Amplify

/// This class provides a SQLite implementation of `AWSLocationStorageBehavior`
/// to locally persist device tracking locations for the cases when the device is
/// offline or to enable batch sending of device tracking locations to `AWSLocation`
/// service
final class AWSLocationStore : AWSLocationStorageBehavior {
    
    let positionsDatabaseName = "geo_device_tracking_positions_store"
    let positionsTable = Table("positions")
    let id = Expression<String>(Position.keys.id.stringValue)
    let timeStamp = Expression<String>(Position.keys.timeStamp.stringValue)
    let latitude = Expression<Double>(Position.keys.latitude.stringValue)
    let longitude = Expression<Double>(Position.keys.longitude.stringValue)
    let tracker = Expression<String>(Position.keys.tracker.stringValue)
    let deviceID = Expression<String>(Position.keys.deviceID.stringValue)
    
    let positionsDatabase: Connection
    
    init() throws {
        guard let urlPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Fatal.error("URL path to documents directory could not be found")
        }
        positionsDatabase = try Connection("\(urlPath)/\(positionsDatabaseName).db")
        try positionsDatabase.run(positionsTable.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(timeStamp)
            t.column(latitude)
            t.column(longitude)
            t.column(tracker)
            t.column(deviceID)
        })
    }
    
    func save(position: Position) throws {
        try positionsDatabase.run(positionsTable.insert(position))
    }
    
    func save(positions: [Position]) throws {
        try positionsDatabase.run(positionsTable.insertMany(positions))
    }
    
    func delete(position: Position) throws {
        let deleteQuery = positionsTable.filter(id == position.id)
        try positionsDatabase.run(deleteQuery.delete())
    }
    
    func delete(positions: [Position]) throws {
        try positionsDatabase.run(positionsTable.filter(positions.map(\.id).contains(id)).delete())
    }
    
    func queryAll() throws -> [Position] {
        try positionsDatabase
            .prepare(positionsTable)
            .map {
                Position(
                    id: $0[id],
                    timeStamp: $0[timeStamp],
                    latitude: $0[latitude],
                    longitude: $0[longitude],
                    tracker: $0[tracker],
                    deviceID: $0[deviceID]
                )
            }
    }
    
    func deleteAll() throws {
        try positionsDatabase.run(positionsTable.delete())
    }
}
