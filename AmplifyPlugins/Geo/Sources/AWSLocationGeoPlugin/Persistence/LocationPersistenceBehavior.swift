//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol LocationPersistenceBehavior {
    
    func insert(position: PositionInternal) async throws
    
    func insert(positions: [PositionInternal]) async throws
    
    func remove(position: PositionInternal) async throws
    
    func remove(positions: [PositionInternal]) async throws
    
    func getAll() async throws -> [PositionInternal]
    
    func removeAll() async throws
    
}
