//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol LocationPersistenceBehavior {
    
    func insert(position: PositionInternal) throws
    
    func insert(positions: [PositionInternal]) throws
    
    func remove(position: PositionInternal) throws
    
    func remove(positions: [PositionInternal]) throws
    
    func getAll() throws -> [PositionInternal]
    
    func removeAll() throws
    
}
