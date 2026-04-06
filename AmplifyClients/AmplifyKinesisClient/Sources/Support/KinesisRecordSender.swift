//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AWSKinesis
import Foundation

/// Protocol wrapper for KinesisClient to enable dependency injection for testing
protocol KinesisClientProtocol {
    func putRecords(input: PutRecordsInput) async throws -> PutRecordsOutput
}

/// Extension to make the SDK KinesisClient conform to the protocol
extension AWSKinesis.KinesisClient: KinesisClientProtocol {}

/// Kinesis-specific implementation of RecordSender
final class KinesisRecordSender: RecordSender, @unchecked Sendable {
    private let kinesisClient: KinesisClientProtocol
    private let maxRetries: Int
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: KinesisRecordSender.self)

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

        let output: PutRecordsOutput = try await kinesisClient.putRecords(input: input)

        var successfulIds: [Int64] = []
        var retryableIds: [Int64] = []
        var failedIds: [Int64] = []

        if records.count != output.records?.count {
            logger.warn("PutRecords response count (\(output.records?.count ?? 0)) does not match request count (\(records.count))")
        }
        for (record, resultEntry) in zip(records, output.records ?? []) {
            if resultEntry.errorCode == nil {
                successfulIds.append(record.id)
            }
            // According to AWS SDK documentation, `PutRecordsResultEntry.errorCode` can be:
            // - `ProvisionedThroughputExceededException`: Retryable - throughput limit exceeded
            // - `InternalFailure`: Retryable - internal service error
            // Both are retried
            else if record.retryCount >= maxRetries {
                failedIds.append(record.id)
            } else {
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
