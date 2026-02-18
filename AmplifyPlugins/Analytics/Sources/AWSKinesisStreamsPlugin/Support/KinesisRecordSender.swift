//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSKinesis

/// Protocol wrapper for KinesisClient to enable dependency injection for testing
/// Implementations must be thread-safe as they will be used from actor contexts
protocol KinesisClientProtocol {
    func putRecords(input: PutRecordsInput) async throws -> PutRecordsOutput
}

/// Extension to make the real KinesisClient conform to the protocol
extension AWSKinesis.KinesisClient: KinesisClientProtocol {}

/// Kinesis-specific implementation of RecordSender
final class KinesisRecordSender: RecordSender, @unchecked Sendable {
    private let kinesisClient: KinesisClientProtocol
    private let maxRetries: Int
    
    init(kinesisClient: KinesisClientProtocol, maxRetries: Int) {
        self.kinesisClient = kinesisClient
        self.maxRetries = maxRetries
    }
    
    func putRecords(streamName: String, records: [Record]) async throws -> PutRecordsResponse {
        guard !records.isEmpty else {
            return PutRecordsResponse(
                successfulIds: [],
                retryableIds: [],
                failedIds: []
            )
        }
        
        let kinesisRecords = records.map { record in
            KinesisClientTypes.PutRecordsRequestEntry(
                data: record.data,
                partitionKey: record.partitionKey
            )
        }
        
        let input = PutRecordsInput(
            records: kinesisRecords,
            streamName: streamName
        )
        
        let output: PutRecordsOutput
        do {
            output = try await kinesisClient.putRecords(input: input)
        } catch {
            throw KinesisError.from(error)
        }
        
        var successfulIds: [Int64] = []
        var retryableIds: [Int64] = []
        var failedIds: [Int64] = []
        
        if (records.count != output.records?.count) {
            // TODO: Log warning
        }
        for (record, resultEntry) in zip(records, output.records ?? []) {
            if resultEntry.errorCode == nil {
                successfulIds.append(record.id)
            }
            // According to AWS SDK documentation, `PutRecordsResultEntry.errorCode` can be:
            // - `ProvisionedThroughputExceededException`: Retryable - throughput limit exceeded
            // - `InternalFailure`: Retryable - internal service error
            // Both are retried
            else if record.retryCount >= self.maxRetries {
                failedIds.append(record.id)
            }
            else {
                retryableIds.append(record.id)
            }
        }
        
        return PutRecordsResponse(
            successfulIds: successfulIds,
            retryableIds: retryableIds,
            failedIds: failedIds
        )
    }
}
