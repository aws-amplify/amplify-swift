//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation
@preconcurrency import SQLite

/// Uses actor for thread-safe access (Swift's recommended approach)
public actor SQLiteRecordStorage: RecordStorage {
    private let database: Connection
    private let cacheMaxBytes: Int64
    private let maxRecords: Int
    private let maxRecordSizeBytes: Int64
    private let maxBytesPerStream: Int64
    private let maxPartitionKeyLength: Int?
    private let hasPartitionKey: Bool
    private var cachedSize: Int64 = 0

    // Table and columns
    private static let records = Table("records")
    private static let id = Expression<Int64>("id")
    private static let streamName = Expression<String>("stream_name")
    private static let partitionKey = Expression<String>("partition_key")
    private static let data = Expression<Data>("data")
    private static let dataSize = Expression<Int>("data_size")
    private static let retryCount = Expression<Int>("retry_count")
    private static let createdAt = Expression<Double>("created_at")

    /// - Parameters:
    ///   - dbPrefix: Prefix for the database file name (e.g. "kinesis_records" or "firehose_records")
    ///   - identifier: Region or unique identifier appended to the database file name
    ///   - maxRecords: Maximum number of records per stream per batch
    ///   - cacheMaxBytes: Maximum total cache size in bytes
    ///   - maxRecordSizeBytes: Maximum size of a single record in bytes
    ///   - maxBytesPerStream: Maximum total payload size per batch in bytes
    ///   - maxPartitionKeyLength: Maximum partition key length in Unicode scalars, or nil if no partition key
    ///   - connection: Optional database connection (for testing)
    public init(
        dbPrefix: String = "kinesis_records",
        identifier: String,
        maxRecords: Int,
        cacheMaxBytes: Int64,
        maxRecordSizeBytes: Int64,
        maxBytesPerStream: Int64,
        maxPartitionKeyLength: Int? = nil,
        connection: Connection? = nil
    ) throws {
        self.identifier = identifier
        self.maxRecords = maxRecords
        self.cacheMaxBytes = cacheMaxBytes
        self.maxRecordSizeBytes = maxRecordSizeBytes
        self.maxBytesPerStream = maxBytesPerStream
        self.maxPartitionKeyLength = maxPartitionKeyLength
        self.hasPartitionKey = maxPartitionKeyLength != nil

        let db = try connection ?? Self.createFileConnection(dbPrefix: dbPrefix, identifier: identifier)
        self.database = db

        try Self.setupSchema(on: db, hasPartitionKey: hasPartitionKey)
        let size = try Self.wrapDatabaseError {
            try db.scalar(Self.records.select(Self.dataSize.sum)) ?? 0
        }
        self.cachedSize = Int64(size)
    }

    /// Keep backward-compatible convenience init for existing Kinesis usage
    private let identifier: String

    private static func createFileConnection(dbPrefix: String, identifier: String) throws -> Connection {
        guard let path = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            throw RecordCacheError.database(
                "Failed to locate application support directory",
                defaultRecoverySuggestion
            )
        }

        let dbPath = path.appendingPathComponent("\(dbPrefix)_\(identifier).db").path
        return try wrapDatabaseError {
            try Connection(dbPath)
        }
    }

    /// Sets up the database schema (tables and indices)
    private static func setupSchema(on connection: Connection, hasPartitionKey: Bool) throws {
        try wrapDatabaseError {
            if hasPartitionKey {
                try connection.run(records.create(ifNotExists: true) { table in
                    table.column(id, primaryKey: .autoincrement)
                    table.column(streamName)
                    table.column(partitionKey)
                    table.column(data)
                    table.column(dataSize)
                    table.column(retryCount, defaultValue: 0)
                    table.column(createdAt, defaultValue: Date().timeIntervalSince1970)
                })
            } else {
                try connection.run(records.create(ifNotExists: true) { table in
                    table.column(id, primaryKey: .autoincrement)
                    table.column(streamName)
                    table.column(data)
                    table.column(dataSize)
                    table.column(retryCount, defaultValue: 0)
                    table.column(createdAt, defaultValue: Date().timeIntervalSince1970)
                })
            }

            try connection.execute("CREATE INDEX IF NOT EXISTS idx_stream_id ON records (stream_name, id)")
            try connection.execute("CREATE INDEX IF NOT EXISTS idx_data_size ON records (data_size)")
        }
    }

    public func addRecord(_ input: RecordInput) throws {
        // Validate partition key if this storage requires one
        if hasPartitionKey {
            guard let pk = input.partitionKey else {
                throw RecordCacheError.validation(
                    "Partition key is required",
                    "Provide a partition key between 1 and \(maxPartitionKeyLength!) characters."
                )
            }
            let partitionKeyScalarCount = pk.unicodeScalars.count
            if partitionKeyScalarCount == 0 || partitionKeyScalarCount > maxPartitionKeyLength! {
                throw RecordCacheError.validation(
                    "Partition key length \(partitionKeyScalarCount) is outside the allowed range of 1–\(maxPartitionKeyLength!) characters",
                    "Use a partition key between 1 and \(maxPartitionKeyLength!) characters."
                )
            }
        }

        // Validate per-record size limit
        if Int64(input.dataSize) > maxRecordSizeBytes {
            throw RecordCacheError.validation(
                "Record size \(input.dataSize) bytes exceeds the maximum of \(maxRecordSizeBytes) bytes",
                "Reduce the size of the data so it does not exceed \(maxRecordSizeBytes) bytes."
            )
        }

        // Check cache size limit before adding
        if cachedSize + Int64(input.dataSize) > cacheMaxBytes {
            throw RecordCacheError.limitExceeded(
                "Cache size limit exceeded: \(cachedSize + Int64(input.dataSize)) bytes > \(cacheMaxBytes) bytes",
                "Call flush() to send cached records or increase the cacheMaxBytes option."
            )
        }

        let insert: Insert
        if hasPartitionKey {
            insert = Self.records.insert(
                Self.streamName <- input.streamName,
                Self.partitionKey <- (input.partitionKey ?? ""),
                Self.data <- input.data,
                Self.dataSize <- input.dataSize,
                Self.retryCount <- 0,
                Self.createdAt <- Date().timeIntervalSince1970
            )
        } else {
            insert = Self.records.insert(
                Self.streamName <- input.streamName,
                Self.data <- input.data,
                Self.dataSize <- input.dataSize,
                Self.retryCount <- 0,
                Self.createdAt <- Date().timeIntervalSince1970
            )
        }

        _ = try Self.wrapDatabaseError {
            try database.run(insert)
        }
        cachedSize += Int64(input.dataSize)
    }

    public func getRecordsByStream(afterIdByStream: [String: Int64] = [:]) throws -> [[Record]] {
        try Self.wrapDatabaseError {
            // Build per-stream WHERE clauses
            let streamFilter: String
            if afterIdByStream.isEmpty {
                streamFilter = ""
            } else {
                let conditions = afterIdByStream.map { _ in
                    "NOT (stream_name = ? AND id <= ?)"
                }.joined(separator: " AND ")
                streamFilter = "WHERE \(conditions)"
            }

            let partitionKeySelect = hasPartitionKey ? "partition_key," : ""
            let query = """
                SELECT id, stream_name, \(partitionKeySelect) data, data_size, retry_count, created_at
                FROM (
                    SELECT *,
                           ROW_NUMBER() OVER (PARTITION BY stream_name ORDER BY id) as rn,
                           SUM(data_size) OVER (PARTITION BY stream_name ORDER BY id) as running_size
                    FROM records
                    \(streamFilter)
                )
                WHERE rn <= ? AND running_size <= ?
                ORDER BY stream_name, id
                """

            // Bind per-stream after-id filters
            var bindings: [Binding?] = afterIdByStream.flatMap { streamName, afterId in
                [streamName as Binding?, afterId as Binding?]
            }
            bindings.append(maxRecords as Binding?)
            bindings.append(maxBytesPerStream as Binding?)

            var recordsByStream: [String: [Record]] = [:]

            let expectedColumns = hasPartitionKey ? 7 : 6
            for row: Statement.Element in try database.prepare(query, bindings) {
                guard row.count >= expectedColumns else {
                    throw RecordCacheError.database(
                        "Unexpected row format: expected \(expectedColumns) columns, got \(row.count)",
                        defaultRecoverySuggestion
                    )
                }

                if hasPartitionKey {
                    guard let id = row[0] as? Int64,
                          let streamName = row[1] as? String,
                          let partitionKey = row[2] as? String,
                          let blob = row[3] as? SQLite.Blob,
                          let retryCount = row[5] as? Int64,
                          let createdAt = row[6] as? Double else {
                        throw RecordCacheError.database(
                            "Failed to parse record from database",
                            defaultRecoverySuggestion
                        )
                    }

                    let record = Record(
                        id: id,
                        streamName: streamName,
                        partitionKey: partitionKey,
                        data: Data(blob.bytes),
                        retryCount: Int(retryCount),
                        createdAt: Date(timeIntervalSince1970: createdAt)
                    )
                    recordsByStream[record.streamName, default: []].append(record)
                } else {
                    guard let id = row[0] as? Int64,
                          let streamName = row[1] as? String,
                          let blob = row[2] as? SQLite.Blob,
                          let retryCount = row[4] as? Int64,
                          let createdAt = row[5] as? Double else {
                        throw RecordCacheError.database(
                            "Failed to parse record from database",
                            defaultRecoverySuggestion
                        )
                    }

                    let record = Record(
                        id: id,
                        streamName: streamName,
                        partitionKey: nil,
                        data: Data(blob.bytes),
                        retryCount: Int(retryCount),
                        createdAt: Date(timeIntervalSince1970: createdAt)
                    )
                    recordsByStream[record.streamName, default: []].append(record)
                }
            }

            return Array(recordsByStream.values)
        }
    }

    public func deleteRecords(ids: [Int64]) throws {
        guard !ids.isEmpty else { return }

        try Self.wrapDatabaseError {
            let placeholders = ids.map { _ in "?" }.joined(separator: ",")
            let sql = "DELETE FROM records WHERE id IN (\(placeholders))"

            let statement = try database.prepare(sql)
            try statement.run(ids.map { $0 as Binding })
        }

        try resetCacheSizeFromDb()
    }

    public func incrementRetryCount(ids: [Int64]) throws {
        guard !ids.isEmpty else { return }

        try Self.wrapDatabaseError {
            let placeholders = ids.map { _ in "?" }.joined(separator: ",")
            let sql = "UPDATE records SET retry_count = retry_count + 1 WHERE id IN (\(placeholders))"

            let statement = try database.prepare(sql)
            try statement.run(ids.map { $0 as Binding })
        }
    }

    public func clearRecords() throws -> Int {
        let count = try Self.wrapDatabaseError {
            let count = try database.scalar(Self.records.count)
            try database.run(Self.records.delete())
            return count
        }
        cachedSize = 0
        return count
    }

    public func getCurrentCacheSize() throws -> Int64 {
        return cachedSize
    }

    /// Resets the cached size by recalculating from the database
    private func resetCacheSizeFromDb() throws {
        let size = try Self.wrapDatabaseError {
            try database.scalar(Self.records.select(Self.dataSize.sum)) ?? 0
        }
        cachedSize = Int64(size)
    }

    /// Wraps a throwing closure so that any non-RecordCacheError is converted
    /// to `.database` with the underlying SQLite error attached.
    private static func wrapDatabaseError<T>(_ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch let error as RecordCacheError {
            throw error
        } catch {
            throw RecordCacheError.database(
                "A database error occurred",
                defaultRecoverySuggestion,
                error
            )
        }
    }
}
