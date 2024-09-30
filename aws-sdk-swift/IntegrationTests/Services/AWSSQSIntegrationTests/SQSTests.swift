//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSSQS
import ClientRuntime
import AWSClientRuntime

/// Tests AWS SQS queue creation and deletion.
class SQSTests: XCTestCase {
    
    private var client: SQSClient!
    private var queueName: String!
    private var queueUrl: String?
    private let region = "us-west-2"

    override func setUp() async throws {
        self.client = try SQSClient(region: "us-west-1")
        queueName = "integration-test-queue-\(UUID().uuidString)"
    }

    override func tearDown() async throws {
        if let queueUrl = queueUrl {
            do {
                _ = try await client.deleteQueue(input: .init(queueUrl: queueUrl))
            } catch {
                XCTFail("Error in tearDown: \(error)")
            }
        }
        // Else, nothing to clean up as the queue was not created.
    }
    
    func test_QueueCreation() async throws {
        let response = try await client.createQueue(input: .init(queueName: queueName))
        queueUrl = response.queueUrl

        XCTAssertNotNil(response.queueUrl, "Queue URL should not be nil")
        XCTAssertTrue(response.queueUrl?.contains(queueName) ?? false, "Queue URL should contain the queue name.")
    }
}
