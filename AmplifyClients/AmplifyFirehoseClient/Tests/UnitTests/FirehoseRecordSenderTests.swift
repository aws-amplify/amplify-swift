//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSFirehose
import XCTest
@testable import AmplifyFirehoseClient
@testable import AmplifyRecordCache

class FirehoseRecordSenderTests: XCTestCase {

    private let testStreamName = "test-delivery-stream"
    private let maxRetries = 3

    /// Test that putRecords constructs the correct PutRecordBatchInput.
    ///
    /// - Given: Two records with test data
    /// - When:
    ///    - putRecords is called
    /// - Then:
    ///    - The captured input has the correct delivery stream name and record data
    ///
    func testCreateRequestShouldConstructCorrectPutRecordBatchInput() async throws {
        let mockClient = MockFirehoseClient()
        let recordSender = FirehoseRecordSender(firehoseClient: mockClient, maxRetries: maxRetries)

        let records = [
            createTestRecord(id: 1, data: Data([1, 2, 3])),
            createTestRecord(id: 2, data: Data([4, 5, 6]))
        ]

        mockClient.mockResponse = PutRecordBatchOutput(
            failedPutCount: 0,
            requestResponses: [
                FirehoseClientTypes.PutRecordBatchResponseEntry(recordId: "id1"),
                FirehoseClientTypes.PutRecordBatchResponseEntry(recordId: "id2")
            ]
        )

        _ = try await recordSender.putRecords(streamName: testStreamName, records: records)

        let captured = try XCTUnwrap(mockClient.capturedInput)
        XCTAssertEqual(captured.deliveryStreamName, testStreamName)
        XCTAssertEqual(captured.records?.count, 2)
        XCTAssertEqual(captured.records?[0].data, Data([1, 2, 3]))
        XCTAssertEqual(captured.records?[1].data, Data([4, 5, 6]))
    }

    /// Test that response entries are correctly categorized into successful, retryable, and failed.
    ///
    /// - Given: Three records — one succeeds, one has a retryable error, one has exhausted retries
    /// - When:
    ///    - putRecords is called and the response contains mixed results
    /// - Then:
    ///    - successfulIds, retryableIds, and failedIds are populated correctly
    ///
    func testSplitResponseShouldCorrectlyCategorizeRecords() async throws {
        let mockClient = MockFirehoseClient()
        let recordSender = FirehoseRecordSender(firehoseClient: mockClient, maxRetries: maxRetries)

        let records = [
            createTestRecord(id: 1, data: Data([1]), retryCount: 0),       // Success
            createTestRecord(id: 2, data: Data([2]), retryCount: 1),       // Retryable
            createTestRecord(id: 3, data: Data([3]), retryCount: maxRetries) // Failed (exhausted)
        ]

        mockClient.mockResponse = PutRecordBatchOutput(
            failedPutCount: 2,
            requestResponses: [
                FirehoseClientTypes.PutRecordBatchResponseEntry(recordId: "id1"),
                FirehoseClientTypes.PutRecordBatchResponseEntry(
                    errorCode: "ServiceUnavailableException",
                    errorMessage: "Service unavailable"
                ),
                FirehoseClientTypes.PutRecordBatchResponseEntry(
                    errorCode: "InternalFailure",
                    errorMessage: "Internal error"
                )
            ]
        )

        let response = try await recordSender.putRecords(streamName: testStreamName, records: records)

        XCTAssertEqual(response.successfulIds, [1])
        XCTAssertEqual(response.retryableIds, [2])
        XCTAssertEqual(response.failedIds, [3])
    }

    /// Test that an empty records array returns an empty response without calling the API.
    ///
    /// - Given: An empty records array
    /// - When:
    ///    - putRecords is called
    /// - Then:
    ///    - All ID arrays are empty and the mock client was not called
    ///
    func testEmptyRecordsShouldReturnEmptyResponse() async throws {
        let mockClient = MockFirehoseClient()
        let recordSender = FirehoseRecordSender(firehoseClient: mockClient, maxRetries: maxRetries)

        let response = try await recordSender.putRecords(streamName: testStreamName, records: [])

        XCTAssertTrue(response.successfulIds.isEmpty)
        XCTAssertTrue(response.retryableIds.isEmpty)
        XCTAssertTrue(response.failedIds.isEmpty)
        XCTAssertNil(mockClient.capturedInput, "Should not call the API for empty records")
    }

    private func createTestRecord(
        id: Int64,
        data: Data,
        retryCount: Int = 0
    ) -> Record {
        Record(
            id: id,
            streamName: testStreamName,
            partitionKey: nil,
            data: data,
            retryCount: retryCount,
            createdAt: Date()
        )
    }
}

// MARK: - Mock Firehose Client

class MockFirehoseClient: FirehoseClientProtocol {
    var mockResponse: PutRecordBatchOutput?
    var capturedInput: PutRecordBatchInput?

    func putRecordBatch(input: PutRecordBatchInput) async throws -> PutRecordBatchOutput {
        capturedInput = input
        guard let response = mockResponse else {
            throw FirehoseTestError.noMockResponse
        }
        return response
    }
}

enum FirehoseTestError: Error {
    case noMockResponse
}
