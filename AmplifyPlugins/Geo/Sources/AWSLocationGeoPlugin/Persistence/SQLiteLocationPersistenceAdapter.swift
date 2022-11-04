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
    
    static let tableName = "positions"
    let positionsTable = Table(tableName)
    let id = Expression<String>(PositionInternal.keys.id.stringValue)
    let timeStamp = Expression<Date>(PositionInternal.keys.timeStamp.stringValue)
    let latitude = Expression<Double>(PositionInternal.keys.latitude.stringValue)
    let longitude = Expression<Double>(PositionInternal.keys.longitude.stringValue)
    let tracker = Expression<String>(PositionInternal.keys.tracker.stringValue)
    let deviceID = Expression<String>(PositionInternal.keys.deviceID.stringValue)
    
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
            t.column(deviceID)
        })
    }
    
    func insert(position: PositionInternal) throws {
        try positionsDatabase.run(positionsTable.insert(position))
    }
    
    func insert(positions: [PositionInternal]) throws {
        try positionsDatabase.run(positionsTable.insertMany(positions))
    }
    
    func remove(position: PositionInternal) throws {
        let deleteQuery = positionsTable.filter(id == position.id)
        try positionsDatabase.run(deleteQuery.delete())
    }
    
    func remove(positions: [PositionInternal]) throws {
        try positionsDatabase.run(positionsTable.filter(positions.map(\.id).contains(id)).delete())
    }
    
    func getAll() throws -> [PositionInternal] {
        try positionsDatabase
            .prepare(positionsTable)
            .map {
                PositionInternal(
                    id: $0[id],
                    timeStamp: $0[timeStamp],
                    latitude: $0[latitude],
                    longitude: $0[longitude],
                    tracker: $0[tracker],
                    deviceID: $0[deviceID]
                )
            }
    }
    
    func removeAll() throws {
        try positionsDatabase.run(positionsTable.delete())
    }
    
}
