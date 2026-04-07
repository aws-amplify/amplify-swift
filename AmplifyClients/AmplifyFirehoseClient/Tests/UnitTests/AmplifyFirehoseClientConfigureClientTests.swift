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
@testable import AmplifyFirehoseClient
@testable import AmplifyRecordCache
@testable import AWSFirehose

class AmplifyFirehoseClientConfigureClientTests: XCTestCase {

    /// Test that the configureClient closure is applied to the SDK configuration.
    ///
    /// - Given: A configureClient closure that sets maxRetriesBase to 10
    /// - When:
    ///    - AmplifyFirehoseClient is initialized
    /// - Then:
    ///    - The underlying SDK client config reflects the custom retry setting
    ///
    func testConfigureClientAppliesConfiguration() throws {
        let client = try AmplifyFirehoseClient(
            region: "us-east-1",
            credentialsProvider: MockFirehoseCredentialsProvider(),
            options: AmplifyFirehoseClient.Options(
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

        XCTAssertNotNil(client.getFirehoseClient())
        let sdkConfig = client.getFirehoseClient().config
        XCTAssertEqual(
            sdkConfig.retryStrategyOptions.maxRetriesBase,
            10,
            "retryStrategyOptions.maxRetriesBase should reflect the value set in configureClient"
        )
    }
}
