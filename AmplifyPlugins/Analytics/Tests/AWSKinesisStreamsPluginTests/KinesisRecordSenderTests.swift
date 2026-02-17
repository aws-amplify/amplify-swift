//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSKinesisStreamsPlugin
import AWSKinesis

class KinesisRecordSenderTests: XCTestCase {
    
    private let testStreamName = "test-stream"
    private let maxRetries = 3
    
    func testSplitResponseShouldCorrectlyCategorizeRecords() async throws {
        // Given
        let mockClient = MockKinesisClient()
        let recordSender = KinesisRecordSender(kinesisClient: mockClient, maxRetries: maxRetries)
        
        let records = [
            createTestRecord(id: 1, partitionKey: "key1", data: Data([1]), retryCount: 0), // Success
            createTestRecord(id: 2, partitionKey: "key2", data: Data([2]), retryCount: 1), // Retryable
            createTestRecord(id: 3, partitionKey: "key3", data: Data([3]), retryCount: maxRetries) // Failed
        ]
        
        // Configure mock response
        mockClient.mockResponse = PutRecordsOutput(
            records: [
                KinesisClientTypes.PutRecordsResultEntry(
                    errorCode: nil,
                    sequenceNumber: "seq1",
                    shardId: "shard1"
                ),
                KinesisClientTypes.PutRecordsResultEntry(
                    errorCode: "ProvisionedThroughputExceededException",
                    sequenceNumber: nil,
                    shardId: nil
                ),
                KinesisClientTypes.PutRecordsResultEntry(
                    errorCode: "InternalFailure",
                    sequenceNumber: nil,
                    shardId: nil
                )
            ]
        )
        
        // When
        let response = try await recordSender.putRecords(streamName: testStreamName, records: records)
        
        // Then
        XCTAssertEqual(response.successfulIds, [1])
        XCTAssertEqual(response.retryableIds, [2])
        XCTAssertEqual(response.failedIds, [3])
    }
    
    private func createTestRecord(
        id: Int64,
        partitionKey: String,
        data: Data,
        retryCount: Int = 0
    ) -> Record {
        return Record(
            id: id,
            streamName: testStreamName,
            partitionKey: partitionKey,
            data: data,
            retryCount: retryCount,
            createdAt: Date()
        )
    }
}

// MARK: - Mock Kinesis Client

class MockKinesisClient: KinesisClientProtocol {
    var mockResponse: PutRecordsOutput?
    
    func putRecords(input: PutRecordsInput) async throws -> PutRecordsOutput {
        guard let response = mockResponse else {
            throw TestError.noMockResponse
        }
        return response
    }
}

enum TestError: Error {
    case noMockResponse
}
