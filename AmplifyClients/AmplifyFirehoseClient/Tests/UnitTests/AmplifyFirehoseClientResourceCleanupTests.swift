//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import XCTest
@testable import AmplifyFirehoseClient
@testable import AmplifyRecordCache

/// Mock credentials provider for Firehose testing
struct MockFirehoseCredentialsProvider: AmplifyFoundation.AWSCredentialsProvider {
    func resolve() async throws -> AmplifyFoundation.AWSCredentials {
        MockFirehoseCredentials()
    }
}

struct MockFirehoseCredentials: AmplifyFoundation.AWSCredentials {
    var accessKeyId: String { "mock-access-key" }
    var secretAccessKey: String { "mock-secret-key" }
}

class AmplifyFirehoseClientResourceCleanupTests: XCTestCase {

    func testDeinitStopsScheduler() async throws {
        weak var weakFirehose: AmplifyFirehoseClient?

        do {
            let firehose = try AmplifyFirehoseClient(
                region: "us-east-1",
                credentialsProvider: MockFirehoseCredentialsProvider(),
                options: AmplifyFirehoseClient.Options(
                    flushStrategy: .interval(1)
                )
            )

            weakFirehose = firehose

            await firehose.enable()
            XCTAssertNotNil(weakFirehose)

            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        XCTAssertNil(weakFirehose, "AmplifyFirehoseClient should be deallocated")
    }
}
