//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AmplifyFoundation
@testable import AmplifyFoundationBridge

class AWSCredentialsSDKTests: XCTestCase {
    /// Given: A credentials that will expire after 100 second
    /// When: I convert the credentials to AWS SDK ClientRuntime
    /// Then: I should get a valid CRT credentials
    func testValidCredentialsToCRTConversion() throws {

        let credentials = MockCredentials(
            sessionToken: "somesession",
            accessKeyId: "accessKeyId",
            secretAccessKey: "secretAccessKey",
            expiration: Date().addingTimeInterval(100)
        )
        let sdkCredentials = try credentials.toAWSSDKCredentials()
        XCTAssertNotNil(sdkCredentials)
    }

    /// Given: A credentials that expired 100 second back
    /// When: I convert the credentials to AWS SDK ClientRuntime
    /// Then: I should get a valid CRT credentials
    func testExpiredCredentialsToCRTConversion() throws {

        let credentials = MockCredentials(
            sessionToken: "somesession",
            accessKeyId: "accessKeyId",
            secretAccessKey: "secretAccessKey",
            expiration: Date().addingTimeInterval(-100)
        )
        let sdkCredentials = try credentials.toAWSSDKCredentials()
        XCTAssertNotNil(sdkCredentials)
    }
}

struct MockCredentials: AWSTemporaryCredentials {
    let sessionToken: String
    let accessKeyId: String
    let secretAccessKey: String
    let expiration: Date
}
