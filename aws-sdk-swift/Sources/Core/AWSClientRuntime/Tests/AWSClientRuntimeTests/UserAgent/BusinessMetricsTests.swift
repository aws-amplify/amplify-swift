//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import ClientRuntime
@testable import AWSClientRuntime
import SmithyRetriesAPI
import SmithyHTTPAuthAPI
import SmithyIdentity
import SmithyRetriesAPI
import Smithy

class BusinessMetricsTests: XCTestCase {
    var context: Context!

    override func setUp() async throws {
        context = Context(attributes: Attributes())
    }

    func test_business_metrics_section_truncation() {
        context.businessMetrics = ["SHORT_FILLER": "A"]
        let longMetricValue = String(repeating: "F", count: 1025)
        context.businessMetrics = ["LONG_FILLER": longMetricValue]
        let userAgent = AWSUserAgentMetadata.fromConfigAndContext(
            serviceID: "test",
            version: "1.0",
            config: UserAgentValuesFromConfig(appID: nil, endpoint: nil, awsRetryMode: .standard),
            context: context
        )
        // Assert values in context match with values assigned to user agent
        XCTAssertEqual(userAgent.businessMetrics?.features, context.businessMetrics)
        // Assert string gets truncated successfully
        let expectedTruncatedString = "m/A,E"
        XCTAssertEqual(userAgent.businessMetrics?.description, expectedTruncatedString)
    }

    func test_multiple_flags_in_context() {
        context.businessMetrics = ["FIRST": "A"]
        context.businessMetrics = ["SECOND": "B"]
        context.setSelectedAuthScheme(SelectedAuthScheme( // S
            schemeID: "aws.auth#sigv4a",
            identity: nil,
            signingProperties: nil,
            signer: nil
        ))
        let userAgent = AWSUserAgentMetadata.fromConfigAndContext(
            serviceID: "test",
            version: "1.0",
            config: UserAgentValuesFromConfig(appID: nil, endpoint: "test-endpoint", awsRetryMode: .adaptive),
            context: context
        )
        // F comes from retry mode being adaptive & N comes from endpoint override
        let expectedString = "m/A,B,F,N,S"
        XCTAssertEqual(userAgent.businessMetrics?.description, expectedString)
    }
}
