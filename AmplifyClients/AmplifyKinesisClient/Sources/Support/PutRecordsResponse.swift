//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Response from putting records to a stream
struct PutRecordsResponse: Sendable {
    let successfulIds: [Int64]
    let retryableIds: [Int64]
    let failedIds: [Int64]
}
