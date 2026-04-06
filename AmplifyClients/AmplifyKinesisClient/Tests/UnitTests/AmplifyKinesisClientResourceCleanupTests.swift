//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import XCTest
@testable import AmplifyKinesisClient

/// Mock credentials provider for testing
struct MockCredentialsProvider: AmplifyFoundation.AWSCredentialsProvider {
    func resolve() async throws -> AmplifyFoundation.AWSCredentials {
        return MockCredentials()
    }
}

struct MockCredentials: AmplifyFoundation.AWSCredentials {
    var accessKeyId: String {
        "mock-access-key"
    }
    var secretAccessKey: String {
        "mock-secret-key"
    }
}

class AmplifyKinesisClientResourceCleanupTests: XCTestCase {

    func testDeinitStopsScheduler() async throws {
        // Create a weak reference to track deallocation
        weak var weakKinesis: AmplifyKinesisClient?

        // Create AmplifyKinesisClient in a scope that will end
        do {
            let kinesis = try AmplifyKinesisClient(
                region: "us-east-1",
                credentialsProvider: MockCredentialsProvider(),
                options: AmplifyKinesisClient.Options(
                    flushStrategy: .interval(1) // Short interval for testing
                )
            )

            weakKinesis = kinesis

            // Enable the scheduler
            await kinesis.enable()

            // Verify it's alive
            XCTAssertNotNil(weakKinesis)

            // Let it run briefly
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        // After scope ends, kinesis should be deallocated
        // Give it a moment for deallocation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Verify the object was deallocated (deinit was called)
        XCTAssertNil(weakKinesis, "AmplifyKinesisClient should be deallocated")
    }
}
