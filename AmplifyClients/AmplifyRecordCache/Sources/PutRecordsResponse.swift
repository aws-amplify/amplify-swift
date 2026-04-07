//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Response from putting records to a stream
package struct PutRecordsResponse: Sendable {
    package let successfulIds: [Int64]
    package let retryableIds: [Int64]
    package let failedIds: [Int64]

    package init(successfulIds: [Int64], retryableIds: [Int64], failedIds: [Int64]) {
        self.successfulIds = successfulIds
        self.retryableIds = retryableIds
        self.failedIds = failedIds
    }
}
