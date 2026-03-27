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
@testable import AWSKinesis
@testable import AmplifyKinesisClient

class AmplifyKinesisClientConfigureClientTests: XCTestCase {

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
