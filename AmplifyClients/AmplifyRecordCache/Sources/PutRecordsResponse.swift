//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Response from putting records to a stream
public struct PutRecordsResponse: Sendable {
    public let successfulIds: [Int64]
    public let retryableIds: [Int64]
    public let failedIds: [Int64]

    public init(successfulIds: [Int64], retryableIds: [Int64], failedIds: [Int64]) {
        self.successfulIds = successfulIds
        self.retryableIds = retryableIds
        self.failedIds = failedIds
    }
}
