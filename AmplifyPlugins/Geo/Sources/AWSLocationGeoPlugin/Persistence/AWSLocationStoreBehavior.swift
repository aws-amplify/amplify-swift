//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AWSLocationStoreBehavior {
    
    func save(position: PositionInternal) throws
    
    func save(positions: [PositionInternal]) throws
    
    func delete(position: PositionInternal) throws
    
    func delete(positions: [PositionInternal]) throws
    
    func queryAll() throws -> [PositionInternal]
    
    func deleteAll() throws
    
}
