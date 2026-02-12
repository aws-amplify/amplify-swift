//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSKinesisStreamsPlugin

class KinesisDataStreamsResourceCleanupTests: XCTestCase {
    
    func testDeinitStopsScheduler() async throws {
        // Create a weak reference to track deallocation
        weak var weakKinesis: KinesisDataStreams?
        
        // Create KinesisDataStreams in a scope that will end
        do {
            let kinesis = try KinesisDataStreams(
                region: "us-east-1",
                options: KinesisDataStreams.Options(
                    flushStrategy: .interval(.seconds(1)) // Short interval for testing
                )
            )
            
            weakKinesis = kinesis
            
            // Enable the scheduler
            await kinesis.enable()
            
            // Verify it's alive
            XCTAssertNotNil(weakKinesis)
            
            // Let it run briefly
            try await Task.sleep(for: .milliseconds(100))
        }
        
        // After scope ends, kinesis should be deallocated
        // Give it a moment for deallocation to complete
        try await Task.sleep(for: .milliseconds(100))
        
        // Verify the object was deallocated (deinit was called)
        XCTAssertNil(weakKinesis, "KinesisDataStreams should be deallocated")
    }
}
