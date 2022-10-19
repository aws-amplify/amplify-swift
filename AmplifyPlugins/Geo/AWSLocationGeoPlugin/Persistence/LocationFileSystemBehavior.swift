//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite

protocol LocationFileSystemBehavior {
    
    func getLocationDBConnection() throws -> Connection
    
}
