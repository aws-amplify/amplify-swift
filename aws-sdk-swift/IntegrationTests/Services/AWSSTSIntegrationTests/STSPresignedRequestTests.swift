//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSSTS
import ClientRuntime
import AWSClientRuntime
import AWSSDKHTTPAuth

/// Tests presigned request using STS::getCallerIdentity.
class STSPresignedRequestTests: XCTestCase {
    private var stsConfig: STSClient.STSClientConfiguration!

    override func setUp() async throws {
        try await super.setUp()
        stsConfig = try await STSClient.STSClientConfiguration(region: "us-east-1")
        stsConfig.authSchemes = [SigV4AuthScheme()]
    }

    func testGetCallerIdentity() async throws {
        let presignedRequest = try await GetCallerIdentityInput().presign(
            config: stsConfig,
            expiration: 60
        )
        guard let presignedRequest else {
            XCTFail("Presigning GetCallerIdentityInput failed.")
            // return added for compiler to not complain.
            return
        }
        let httpResponse = try await stsConfig.httpClientEngine.send(request: presignedRequest)
        XCTAssertEqual(httpResponse.statusCode.rawValue, 200)
    }
}
