//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents a record stored locally
public struct Record: Sendable {
    public let id: Int64
    public let streamName: String
    public let partitionKey: String?
    public let data: Data
    public var dataSize: Int {
        data.count + (partitionKey?.utf8.count ?? 0)
    }
    public let retryCount: Int
    public let createdAt: Date

    public init(
        id: Int64,
        streamName: String,
        partitionKey: String?,
        data: Data,
        retryCount: Int,
        createdAt: Date
    ) {
        self.id = id
        self.streamName = streamName
        self.partitionKey = partitionKey
        self.data = data
        self.retryCount = retryCount
        self.createdAt = createdAt
    }
}

/// Input for recording a new record
public struct RecordInput: Sendable {
    public let streamName: String
    public let partitionKey: String?
    public let data: Data
    public var dataSize: Int {
        data.count + (partitionKey?.utf8.count ?? 0)
    }

    public init(streamName: String, partitionKey: String? = nil, data: Data) {
        self.streamName = streamName
        self.partitionKey = partitionKey
        self.data = data
    }
}
