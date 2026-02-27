//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSKinesisStreamsPlugin
import AmplifyFoundation
import AWSKinesis
import SmithyHTTPAPI

/// Mock HTTP client engine that captures the User-Agent header from outgoing requests.
private class UserAgentCapturingEngine: HTTPClient {
    var capturedUserAgent: String?

    func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        capturedUserAgent = request.headers.value(for: "User-Agent")
        // Throw to short-circuit the request — we only need to capture the header
        throw URLError(.cancelled)
    }
}

class AmplifyKinesisClientUserAgentTests: XCTestCase {

    func testUserAgentContainsKinesisMetadata() async throws {
        let capturingEngine = UserAgentCapturingEngine()

        let client = try AmplifyKinesisClient(
            region: "us-east-1",
            credentialsProvider: MockCredentialsProvider(),
            options: AmplifyKinesisClient.Options(
                flushStrategy: .none,
                configureClient: { config in
                    // Replace the HTTP engine with our capturing engine.
                    // KinesisUserAgentClientEngine wraps whatever engine is set,
                    // so we set our capturing engine BEFORE the client applies its wrapper.
                    config.httpClientEngine = capturingEngine
                }
            )
        )

        // Call putRecords directly on the SDK client to trigger the interceptor chain.
        // The request will fail (capturing engine throws), but the header is captured.
        let request = PutRecordsInput(
            records: [
                KinesisClientTypes.PutRecordsRequestEntry(
                    data: "test".data(using: .utf8),
                    partitionKey: "key"
                )
            ],
            streamName: "test-stream"
        )

        do {
            _ = try await client.getKinesisClient().putRecords(input: request)
            XCTFail("Expected request to fail")
        } catch {
            // Expected — capturing engine throws to short-circuit
        }

        let userAgent = try XCTUnwrap(capturingEngine.capturedUserAgent, "User-Agent header should be captured")
        XCTAssertTrue(
            userAgent.contains("lib/amplify-swift#\(kinesisPluginVersion)"),
            "User-Agent should contain lib/amplify-swift#\(kinesisPluginVersion), got: \(userAgent)"
        )
        XCTAssertTrue(
            userAgent.contains("md/kinesis#\(kinesisPluginVersion)"),
            "User-Agent should contain md/kinesis#\(kinesisPluginVersion), got: \(userAgent)"
        )
    }
}
