//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents a record stored locally
struct Record: Sendable {
    let id: Int64
    let streamName: String
    let partitionKey: String
    let data: Data
    var dataSize: Int {
        data.count
    }
    let retryCount: Int
    let createdAt: Date
}

/// Input for recording a new record
struct RecordInput: Sendable {
    let streamName: String
    let partitionKey: String
    let data: Data
    var dataSize: Int {
        data.count
    }
}
