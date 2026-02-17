//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol for record storage operations
protocol RecordStorage {
    /// Adds a new record to storage
    func addRecord(_ input: RecordInput) async throws
    
    /// Gets all records grouped by stream name as a list of lists
    func getRecordsByStream() async throws -> [[Record]]
    
    /// Deletes records by their IDs
    func deleteRecords(ids: [Int64]) async throws
    
    /// Increments the retry count for records
    func incrementRetryCount(ids: [Int64]) async throws
    
    /// Clears all records from storage
    func clearRecords() async throws -> Int
    
    /// Gets the current cache size in bytes
    func getCurrentCacheSize() async throws -> Int64
}
