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
final class AWSLocationStoreAdapter : AWSLocationStoreBehavior {
    
    private let locationPersistenceBehavior : LocationPersistenceBehavior

    init(locationPersistenceBehavior: LocationPersistenceBehavior) {
        self.locationPersistenceBehavior = locationPersistenceBehavior
    }
    
    func save(position: Position) throws {
        try self.locationPersistenceBehavior.insert(position: position)
    }
    
    func save(positions: [Position]) throws {
        try self.locationPersistenceBehavior.insert(positions: positions)
    }
    
    func delete(position: Position) throws {
        try self.locationPersistenceBehavior.remove(position: position)
    }
    
    func delete(positions: [Position]) throws {
        try self.locationPersistenceBehavior.remove(positions: positions)
    }
    
    func queryAll() throws -> [Position] {
        try self.locationPersistenceBehavior.getAll()
    }
    
    func deleteAll() throws {
        try self.locationPersistenceBehavior.removeAll()
    }
    
}
