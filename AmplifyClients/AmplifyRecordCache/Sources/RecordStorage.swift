//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol RecordStorage: Actor {
    /// Adds a new record to storage
    func addRecord(_ input: RecordInput) async throws

    /// Gets all records grouped by stream name as a list of lists.
    /// - Parameter afterIdByStream: A map of stream name to the last processed record ID.
    ///   Records with `id <= afterIdByStream[streamName]` are excluded from the results.
    func getRecordsByStream(afterIdByStream: [String: Int64]) async throws -> [[Record]]

    /// Deletes records by their IDs
    func deleteRecords(ids: [Int64]) async throws

    /// Increments the retry count for records
    func incrementRetryCount(ids: [Int64]) async throws

    /// Clears all records from storage
    func clearRecords() async throws -> Int

    /// Gets the current cache size in bytes
    func getCurrentCacheSize() async throws -> Int64
}
