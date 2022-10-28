//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AWSLocationStoreBehavior {
    
    func save(position: Position) async throws
    
    func save(positions: [Position]) async throws
    
    func delete(position: Position) async throws
    
    func delete(positions: [Position]) async throws
    
    func queryAll() async throws -> [Position]
    
    func deleteAll() async throws
    
}
