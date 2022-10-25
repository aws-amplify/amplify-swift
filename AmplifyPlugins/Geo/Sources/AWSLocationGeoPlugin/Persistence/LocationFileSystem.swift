//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import SQLite

class LocationFileSystem: LocationFileSystemBehavior {
    
    private let positionsDatabaseName = "geo_device_tracking_positions_store"
    
    func getLocationDBConnection() throws -> Connection {
        guard let urlPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Fatal.error("URL path to documents directory could not be found")
        }
        
        return try Connection(urlPath.appendingPathComponent("\(positionsDatabaseName).db").absoluteString)
    }
    
}
