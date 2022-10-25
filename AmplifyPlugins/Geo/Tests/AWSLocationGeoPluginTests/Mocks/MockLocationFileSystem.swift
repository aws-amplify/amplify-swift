//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Amplify
import SQLite
@testable import AWSLocationGeoPlugin

class MockLocationFileSystem: LocationFileSystemBehavior {
    
    func getLocationDBConnection() throws -> SQLite.Connection {
        return try Connection(.inMemory)
    }
    
}
