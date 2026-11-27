//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package protocol RecordStorage: Actor {
    /// Adds a new record to storage
    func addRecord(_ input: RecordInput) async throws

    /// Gets all records grouped by stream name as a list of lists.
    /// - Parameter afterIdByStream: A map of stream name to the last processed record ID.
    ///   Records with `id <= afterIdByStream[streamName]` are excluded from the results.
    func getRecordsByStream(afterIdByStream: [String: Int64]) async throws -> [[Record]]

    /// Deletes records by their IDs
    func deleteRecords(ids: [Int64]) async throws

    /// The largest record ID in storage, or `nil` when it holds none. IDs only grow and are never reused, so
    /// every record stored so far has an ID at or below it, and every later one an ID above it.
    func maxRecordId() async throws -> Int64?

    /// Deletes every record whose ID is at or below `id`, in every stream.
    func deleteRecords(upTo id: Int64) async throws

    /// Increments the retry count for records
    func incrementRetryCount(ids: [Int64]) async throws

    /// Clears all records from storage
    func clearRecords() async throws -> Int

    /// Gets the current cache size in bytes
    func getCurrentCacheSize() async throws -> Int64
}
