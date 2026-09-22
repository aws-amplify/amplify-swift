//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import SmithyRetries
import SmithyRetriesAPI
import XCTest
@testable import AmplifyKinesisClient
@testable import AmplifyRecordCache
@testable import AWSKinesis

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AmplifyKinesisClientConfigureClientTests: XCTestCase, @unchecked Sendable {

    /// Verifies that the `configureClient` closure is applied to the underlying
    /// SDK client configuration.
    func testConfigureClientAppliesConfiguration() throws {
        let client = try AmplifyKinesisClient(
            region: "us-east-1",
            credentialsProvider: MockCredentialsProvider(),
            options: AmplifyKinesisClient.Options(
                maxRetries: 3,
                flushStrategy: .none,
                configureClient: { config in
                    config.retryStrategyOptions = RetryStrategyOptions(
                        backoffStrategy: ExponentialBackoffStrategy(),
                        maxRetriesBase: 10
                    )
                }
            )
        )

        XCTAssertNotNil(client.getKinesisClient())
        let sdkConfig = client.getKinesisClient().config
        XCTAssertEqual(
            sdkConfig.retryStrategyOptions.maxRetriesBase,
            10,
            "retryStrategyOptions.maxRetriesBase should reflect the value set in configureClient"
        )
    }
}
