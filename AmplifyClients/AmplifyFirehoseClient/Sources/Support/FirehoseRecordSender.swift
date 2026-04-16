//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AmplifyRecordCache
import AWSFirehose
import Foundation

/// Protocol wrapper for FirehoseClient to enable dependency injection for testing
protocol FirehoseClientProtocol {
    func putRecordBatch(input: PutRecordBatchInput) async throws -> PutRecordBatchOutput
}

/// Extension to make the SDK FirehoseClient conform to the protocol
extension AWSFirehose.FirehoseClient: FirehoseClientProtocol {}

/// Firehose-specific implementation of RecordSender
final class FirehoseRecordSender: AmplifyRecordCache.RecordSender, @unchecked Sendable {
    private let firehoseClient: FirehoseClientProtocol
    private let maxRetries: Int
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: FirehoseRecordSender.self)

    init(firehoseClient: FirehoseClientProtocol, maxRetries: Int) {
        self.firehoseClient = firehoseClient
        self.maxRetries = maxRetries
    }

    func putRecords(streamName: String, records: [AmplifyRecordCache.Record]) async throws -> AmplifyRecordCache.PutRecordsResponse {
        guard !records.isEmpty else {
            return PutRecordsResponse(
                successfulIds: [],
                retryableIds: [],
                failedIds: []
            )
        }

        let firehoseRecords = records.map { record in
            FirehoseClientTypes.Record(data: record.data)
        }

        let input = PutRecordBatchInput(
            deliveryStreamName: streamName,
            records: firehoseRecords
        )

        let output: PutRecordBatchOutput = try await firehoseClient.putRecordBatch(input: input)

        var successfulIds: [Int64] = []
        var retryableIds: [Int64] = []
        var failedIds: [Int64] = []

        if records.count != output.requestResponses?.count {
            logger.warn("PutRecordBatch response count (\(output.requestResponses?.count ?? 0)) does not match request count (\(records.count))")
        }
        for (record, resultEntry) in zip(records, output.requestResponses ?? []) {
            if resultEntry.errorCode == nil {
                successfulIds.append(record.id)
            } else if record.retryCount >= maxRetries {
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
