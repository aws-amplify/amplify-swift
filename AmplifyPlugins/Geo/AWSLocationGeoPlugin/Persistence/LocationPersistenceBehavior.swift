//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol LocationPersistenceBehavior {
    
    func insert(position: Position) throws
    
    func insert(positions: [Position]) throws
    
    func remove(position: Position) throws
    
    func remove(positions: [Position]) throws
    
    func getAll() throws -> [Position]
    
    func removeAll() throws
    
}
