//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AWSLocationStoreBehavior {
    
    func save(position: PositionInternal) async throws
    
    func save(positions: [PositionInternal]) async throws
    
    func delete(position: PositionInternal) async throws
    
    func delete(positions: [PositionInternal]) async throws
    
    func queryAll() async throws -> [PositionInternal]
    
    func deleteAll() async throws
    
}
