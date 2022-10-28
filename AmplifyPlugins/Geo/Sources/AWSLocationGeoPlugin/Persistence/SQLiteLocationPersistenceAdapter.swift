//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import Amplify

/// This class provides a SQLite implementation of `LocationPersistenceBehavior`
/// to locally persist device tracking locations for the cases when the device is
/// offline or to enable batch sending of device tracking locations to `AWSLocation`
/// service
final class SQLiteLocationPersistenceAdapter : LocationPersistenceBehavior {
    
    let positionsTable = Table("positions")
    let id = Expression<String>(Position.keys.id.stringValue)
    let timeStamp = Expression<String>(Position.keys.timeStamp.stringValue)
    let latitude = Expression<Double>(Position.keys.latitude.stringValue)
    let longitude = Expression<Double>(Position.keys.longitude.stringValue)
    let tracker = Expression<String>(Position.keys.tracker.stringValue)
    
    private let positionsDatabase: Connection
    private let fileSystemBehavior: LocationFileSystemBehavior
    
    init(fileSystemBehavior: LocationFileSystemBehavior) throws {
        self.fileSystemBehavior = fileSystemBehavior
        self.positionsDatabase = try fileSystemBehavior.getLocationDBConnection()
        try initialize(connection: positionsDatabase)
    }
    
    private func initialize(connection: Connection) throws {
        try connection.run(positionsTable.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(timeStamp)
            t.column(latitude)
            t.column(longitude)
            t.column(tracker)
        })
    }
    
    func insert(position: Position) throws {
        try positionsDatabase.run(positionsTable.insert(position))
    }
    
    func insert(positions: [Position]) throws {
        try positionsDatabase.run(positionsTable.insertMany(positions))
    }
    
    func remove(position: Position) throws {
        let deleteQuery = positionsTable.filter(id == position.id)
        try positionsDatabase.run(deleteQuery.delete())
    }
    
    func remove(positions: [Position]) throws {
        try positionsDatabase.run(positionsTable.filter(positions.map(\.id).contains(id)).delete())
    }
    
    func getAll() throws -> [Position] {
        try positionsDatabase
            .prepare(positionsTable)
            .map {
                Position(
                    id: $0[id],
                    timeStamp: $0[timeStamp],
                    latitude: $0[latitude],
                    longitude: $0[longitude],
                    tracker: $0[tracker]
                )
            }
    }
    
    func removeAll() throws {
        try positionsDatabase.run(positionsTable.delete())
    }
    
}
