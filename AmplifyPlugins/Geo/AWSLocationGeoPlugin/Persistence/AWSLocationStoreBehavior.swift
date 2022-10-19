//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol AWSLocationStoreBehavior {
    
    func save(position: Position) throws
    
    func save(positions: [Position]) throws
    
    func delete(position: Position) throws
    
    func delete(positions: [Position]) throws
    
    func queryAll() throws -> [Position]
    
    func deleteAll() throws
    
}
