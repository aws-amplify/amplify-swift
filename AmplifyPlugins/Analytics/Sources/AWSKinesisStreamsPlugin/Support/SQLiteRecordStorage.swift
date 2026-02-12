//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@preconcurrency import SQLite

/// Uses actor for thread-safe access (Swift's recommended approach)
actor SQLiteRecordStorage: RecordStorage {
    private let db: Connection
    private let maxBytes: Int64
    private let maxRecords: Int
    private let identifier: String
    private var cachedSize: Int64 = 0

    // Table and columns - defined as static to avoid duplication in setupDatabase
    private static let records = Table("records")
    private static let id = Expression<Int64>("id")
    private static let streamName = Expression<String>("stream_name")
    private static let partitionKey = Expression<String>("partition_key")
    private static let data = Expression<Data>("data")
    private static let dataSize = Expression<Int>("data_size")
    private static let retryCount = Expression<Int>("retry_count")
    private static let createdAt = Expression<Double>("created_at")

    init(identifier: String, maxRecords: Int, maxBytes: Int64) throws {
        self.identifier = identifier
        self.maxRecords = maxRecords
        self.maxBytes = maxBytes

        // Setup database connection and schema
        let connection = try Self.setupDatabase(identifier: identifier)
        self.db = connection
        
        // Initialize cached size from database
        do {
            let size = try connection.scalar(Self.records.select(Self.dataSize.sum)) ?? 0
            self.cachedSize = Int64(size)
        } catch {
            self.cachedSize = 0
        }
    }
    
    /// Sets up the database connection and creates tables/indices if needed
    /// This is a static method so it can be called before the actor is fully initialized
    private static func setupDatabase(identifier: String) throws -> Connection {
        guard let path = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            throw RecordCacheError.storage(
                "Failed to locate application support directory",
                "Ensure app has proper file system permissions"
            )
        }

        let dbPath = path.appendingPathComponent("kinesis_records_\(identifier).db").path
        let connection = try Connection(dbPath)

        try connection.run(records.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(streamName)
            t.column(partitionKey)
            t.column(data)
            t.column(dataSize)
            t.column(retryCount, defaultValue: 0)
            t.column(createdAt, defaultValue: Date().timeIntervalSince1970)
        })

        try connection.execute("CREATE INDEX IF NOT EXISTS idx_stream_id ON records (stream_name, id)")
        try connection.execute("CREATE INDEX IF NOT EXISTS idx_data_size ON records (data_size)")
        
        return connection
    }

    func addRecord(_ input: RecordInput) throws {
        // Check cache size limit before adding 
        if cachedSize + Int64(input.dataSize) > maxBytes {
            throw RecordCacheError.limitExceeded(
                "Cache size limit exceeded: \(cachedSize + Int64(input.dataSize)) bytes > \(maxBytes) bytes",
                "Call flush() to send cached records or increase cache size limit"
            )
        }

        let insert = Self.records.insert(
            Self.streamName <- input.streamName,
            Self.partitionKey <- input.partitionKey,
            Self.data <- input.data,
            Self.dataSize <- input.dataSize,
            Self.retryCount <- 0,
            Self.createdAt <- Date().timeIntervalSince1970
        )
        
        try db.run(insert)
        cachedSize += Int64(input.dataSize)
    }

    func getRecordsByStream() throws -> [[Record]] {
        // Must use raw SQL for window functions
        let query = """
            SELECT id, stream_name, partition_key, data, data_size, retry_count, created_at
            FROM (
                SELECT *, 
                       ROW_NUMBER() OVER (PARTITION BY stream_name ORDER BY id) as rn,
                       SUM(data_size) OVER (PARTITION BY stream_name ORDER BY id) as running_size
                FROM records
            ) 
            WHERE rn <= ? AND running_size <= ?
            ORDER BY stream_name, id
            """
        
        var recordsByStream: [String: [Record]] = [:]
        
        for row in try db.prepare(query, maxRecords, maxBytes) {
            guard let id = row[0] as? Int64,
                  let streamName = row[1] as? String,
                  let partitionKey = row[2] as? String,
                  let blob = row[3] as? SQLite.Blob,
                  let retryCount = row[5] as? Int64,
                  let createdAt = row[6] as? Double else {
                throw RecordCacheError.storage(
                    "Failed to parse record from database",
                    "Database may be corrupted. Try calling clearCache()"
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
        }
        
        // Return as list of lists to match Android
        return Array(recordsByStream.values)
    }

    func deleteRecords(ids: [Int64]) throws {
        guard !ids.isEmpty else { return }

        let placeholders = ids.map { _ in "?" }.joined(separator: ",")
        let sql = "DELETE FROM records WHERE id IN (\(placeholders))"
        
        let statement = try db.prepare(sql)
        try statement.run(ids.map { $0 as Binding })
        
        try resetCacheSizeFromDb()
    }

    func incrementRetryCount(ids: [Int64]) throws {
        guard !ids.isEmpty else { return }

        let placeholders = ids.map { _ in "?" }.joined(separator: ",")
        let sql = "UPDATE records SET retry_count = retry_count + 1 WHERE id IN (\(placeholders))"
        
        let statement = try db.prepare(sql)
        try statement.run(ids.map { $0 as Binding })
    }

    func clearRecords() throws -> Int {
        let count = try db.scalar(Self.records.count)
        try db.run(Self.records.delete())
        cachedSize = 0
        return count
    }

    func getCurrentCacheSize() throws -> Int64 {
        return cachedSize
    }

    /// Resets the cached size by recalculating from the database
    /// Used internally after delete operations to ensure accuracy
    private func resetCacheSizeFromDb() throws {
        let size = try db.scalar(Self.records.select(Self.dataSize.sum)) ?? 0
        cachedSize = Int64(size)
    }
}
