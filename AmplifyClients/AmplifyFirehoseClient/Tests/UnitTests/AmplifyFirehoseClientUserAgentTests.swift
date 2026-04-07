//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AmplifyFoundationBridge
import AWSFirehose
import SmithyHTTPAPI
import XCTest
@testable import AmplifyFirehoseClient
@testable import AmplifyRecordCache

/// Mock HTTP client engine that captures the User-Agent header from outgoing requests.
private class UserAgentCapturingEngine: HTTPClient {
    var capturedUserAgent: String?

    func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        capturedUserAgent = request.headers.value(for: "User-Agent")
        // Throw to short-circuit the request — we only need to capture the header
        throw URLError(.cancelled)
    }
}

class AmplifyFirehoseClientUserAgentTests: XCTestCase {

    func testUserAgentContainsFirehoseMetadata() async throws {
        let capturingEngine = UserAgentCapturingEngine()

        let client = try AmplifyFirehoseClient(
            region: "us-east-1",
            credentialsProvider: MockFirehoseCredentialsProvider(),
            options: AmplifyFirehoseClient.Options(
                flushStrategy: .none,
                configureClient: { config in
                    config.httpClientEngine = capturingEngine
                }
            )
        )

        let request = PutRecordBatchInput(
            deliveryStreamName: "test-stream",
            records: [
                FirehoseClientTypes.Record(data: "test".data(using: .utf8)!)
            ]
        )

        do {
            _ = try await client.getFirehoseClient().putRecordBatch(input: request)
            XCTFail("Expected request to fail")
        } catch {
            // Expected — capturing engine throws to short-circuit
        }

        let userAgent = try XCTUnwrap(capturingEngine.capturedUserAgent, "User-Agent header should be captured")
        let version = AmplifyMetadata.version
        XCTAssertTrue(
            userAgent.contains("lib/amplify-swift#\(version)"),
            "User-Agent should contain lib/amplify-swift#\(version), got: \(userAgent)"
        )
        XCTAssertTrue(
            userAgent.contains("md/amplify-firehose#\(version)"),
            "User-Agent should contain md/amplify-firehose#\(version), got: \(userAgent)"
        )
    }
}
