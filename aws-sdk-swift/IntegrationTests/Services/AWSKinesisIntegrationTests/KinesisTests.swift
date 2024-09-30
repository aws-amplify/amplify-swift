//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSKinesis
import ClientRuntime
import AWSClientRuntime
import SmithyWaitersAPI

class KinesisTests: XCTestCase {

    func test_kinesisIntegrationTest() async throws {
        // Performs a test against "live" AWS Kinesis to ensure that the `subscribeToShard` event streaming operation
        // operates as expected.  Test should take ~20-30 seconds to complete.
        //
        // Streaming is over HTTP/1.1.  Streaming is unidirectional (in the response.)
        // AWS Kinesis uses awsJson1_1 protocol.
        //
        // Client must have AWS credentials set that allow access to the Kinesis service.
        // Resources will be cleaned up before the test concludes, pass or fail, unless the test crashes.

        let streamName = UUID().uuidString
        let client = try KinesisClient(region: "us-west-2")

        do {
            // Create stream named `streamName`, wait until it is fully created, and get its description
            let createStreamInput = CreateStreamInput(shardCount: 1, streamModeDetails: KinesisClientTypes.StreamModeDetails(streamMode: .provisioned), streamName: streamName)
            let _ = try await client.createStream(input: createStreamInput)
            let describeStreamInput = DescribeStreamInput(streamName: streamName)
            let describeStreamOutput = try await client.waitUntilStreamExists(options: WaiterOptions(maxWaitTime: 30.0), input: describeStreamInput)
            guard case .success(let stream) = describeStreamOutput.result else { throw KinesisTestError("could not describe stream") }
            let streamARN = stream.streamDescription?.streamARN

            // Make a set of 10 records, add them to the stream
            var recordStrings = (1...10).map { _ in UUID().uuidString }
            for record in recordStrings {
                let putRecordInput = PutRecordInput(data: record.data(using: .utf8), explicitHashKey: nil, partitionKey: "Test", sequenceNumberForOrdering: nil, streamName: streamName)
                let _ = try await client.putRecord(input: putRecordInput)
            }

            // Get the first (only) shard in the data stream
            let listShardsInput = ListShardsInput(streamName: streamName)
            let shardList = try await client.listShards(input: listShardsInput)
            let shard = shardList.shards?.first!

            // Create a consumer for the shard
            let consumerName = UUID().uuidString
            let consumerInput = RegisterStreamConsumerInput(consumerName: consumerName, streamARN: stream.streamDescription?.streamARN)
            let consumer = try await client.registerStreamConsumer(input: consumerInput)
            let consumerARN = consumer.consumer?.consumerARN

            // Wait until the consumer becomes active
            let describeConsumerInput = DescribeStreamConsumerInput(consumerARN: consumerARN, streamARN: streamARN)
            var counter = 30
            repeat {
                try await Task<Never, Never>.sleep(nanoseconds: 1_000_000_000)
                let out = try await client.describeStreamConsumer(input: describeConsumerInput)
                if out.consumerDescription?.consumerStatus == .active { break }
                counter -= 1
                if counter < 0 { throw KinesisTestError("consumer timed out while waiting for active") }
            } while true

            // Create the subscription stream
            let input = SubscribeToShardInput(consumerARN: consumerARN, shardId: shard?.shardId, startingPosition: KinesisClientTypes.StartingPosition(sequenceNumber: shard?.sequenceNumberRange?.startingSequenceNumber, type: .atSequenceNumber))
            let output = try await client.subscribeToShard(input: input)

            // Monitor the shard event stream
            for try await event in output.eventStream! {
                switch event {
                case .subscribetoshardevent(let event):
                    event.records?.forEach { record in
                        let recordString = String(data: record.data ?? Data(), encoding: .utf8)
                        recordStrings.removeAll { recordString == $0 }
                    }
                case .sdkUnknown(let message):
                    print("Unknown event: \(message)")
                }

                // Once all the events have been received, stop streaming
                if recordStrings.isEmpty { break }
            }

            // Clean up before ending test
            await cleanUpKinesis(client: client, streamName: streamName)
        } catch {
            // If an error is thrown, clean up then rethrow error
            // Test will fail when XCTest catches the error
            await cleanUpKinesis(client: client, streamName: streamName)
            throw error
        }
    }

    private func cleanUpKinesis(client: KinesisClient, streamName: String) async {
        let deleteStreamInput = DeleteStreamInput(enforceConsumerDeletion: true, streamName: streamName)
        _ = try? await client.deleteStream(input: deleteStreamInput)
    }

    private struct KinesisTestError: Error {
        let localizedDescription: String
        init(_ localizedDescription: String) { self.localizedDescription = localizedDescription }
    }
}
