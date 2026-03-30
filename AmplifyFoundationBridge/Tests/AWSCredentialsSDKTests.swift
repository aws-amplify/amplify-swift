//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AwsCommonRuntimeKit
import SmithyIdentity
@testable import AmplifyFoundation
@testable import AmplifyFoundationBridge

class AWSCredentialsSDKTests: XCTestCase {
    /// Given: A credentials that will expire after 100 second
    /// When: I convert the credentials to AWS SDK ClientRuntime
    /// Then: I should get a valid CRT credentials
    func testValidAWSCredentialsToCRTConversion() throws {

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
    func testExpiredAWSCredentialsToCRTConversion() throws {

        let credentials = MockCredentials(
            sessionToken: "somesession",
            accessKeyId: "accessKeyId",
            secretAccessKey: "secretAccessKey",
            expiration: Date().addingTimeInterval(-100)
        )
        let sdkCredentials = try credentials.toAWSSDKCredentials()
        XCTAssertNotNil(sdkCredentials)
    }

    /// Given: A credentials that will expire after 100 second
    /// When: I convert the credentials to AWS SDK ClientRuntime
    /// Then: I should get a valid CRT credentials
    func testValidAWSCredentialsToSmithyConversion() throws {

        let credentials = MockCredentials(
            sessionToken: "somesession",
            accessKeyId: "accessKeyId",
            secretAccessKey: "secretAccessKey",
            expiration: Date().addingTimeInterval(100)
        )
        let smithyCredentials = try credentials.toAWSCredentialIdentity()
        XCTAssertNotNil(smithyCredentials)
    }

    /// Given: A credentials that expired 100 second back
    /// When: I convert the credentials to AWS SDK ClientRuntime
    /// Then: I should get a valid CRT credentials
    func testExpiredAWSCredentialsToSmithyConversion() throws {

        let credentials = MockCredentials(
            sessionToken: "somesession",
            accessKeyId: "accessKeyId",
            secretAccessKey: "secretAccessKey",
            expiration: Date().addingTimeInterval(-100)
        )
        let smithyCredentials = try credentials.toAWSCredentialIdentity()
        XCTAssertNotNil(smithyCredentials)
    }

    /// Given: A smithy credential without expiration and session token
    /// When: I convert the credentials to AWSCredentials
    /// Then: I should get a static AWSCredentials
    func testSmithyCredentialsToStaticAWSCredentialsConversion() throws {
        let credentials = AWSCredentialIdentity(accessKey: "someaccesskey", secret: "somesecret")
        let awsCredentials = try credentials.toAWSCredentials()
        XCTAssertNotNil(awsCredentials)
    }

    /// Given: A smithy credential that will expire after 100 second
    /// When: I convert the credentials to AWSCredentials
    /// Then: I should get a temporary AWSCredentials
    func testValidSmithyCredentialsToTemporaryAWSCredentialsConversion() throws {
        let credentials = AWSCredentialIdentity(
            accessKey: "someaccesskey",
            secret: "somesecret",
            expiration: Date().addingTimeInterval(100),
            sessionToken: "somesession")
        let awsCredentials = try credentials.toAWSCredentials()
        XCTAssertNotNil(awsCredentials)
        XCTAssertNotNil(awsCredentials as? AWSTemporaryCredentials)
    }

    /// Given: A smithy credential that expired 100 second back
    /// When: I convert the credentials to AWSCredentials
    /// Then: I should get a temporary AWSCredentials
    func testExpiredSmithyCredentialsToTemporaryAWSCredentialsConversion() throws {
        let credentials = AWSCredentialIdentity(
            accessKey: "someaccesskey",
            secret: "somesecret",
            expiration: Date().addingTimeInterval(-100),
            sessionToken: "somesession")
        let awsCredentials = try credentials.toAWSCredentials()
        XCTAssertNotNil(awsCredentials)
        XCTAssertNotNil(awsCredentials as? AWSTemporaryCredentials)
    }

    /// Given: A CRT credential without expiration and session token
    /// When: I convert the credentials to AWSCredentials
    /// Then: I should get a static AWSCredentials
    func testCRTCredentialsToStaticAWSCredentialsConversion() throws {
        let credentials = try AwsCommonRuntimeKit.Credentials(accessKey: "someaccesskey", secret: "somesecret")
        let awsCredentials = try credentials.toAWSCredentials()
        XCTAssertNotNil(awsCredentials)
    }

    /// Given: A CRT credential that will expire after 100 second
    /// When: I convert the credentials to AWSCredentials
    /// Then: I should get a temporary AWSCredentials
    func testValidCRTCredentialsToTemporaryAWSCredentialsConversion() throws {
        let credentials = try AwsCommonRuntimeKit.Credentials(
            accessKey: "someaccesskey",
            secret: "somesecret",
            sessionToken: "somesession",
            expiration: Date().addingTimeInterval(100))
        let awsCredentials = try credentials.toAWSCredentials()
        XCTAssertNotNil(awsCredentials)
        XCTAssertNotNil(awsCredentials as? AWSTemporaryCredentials)
    }

    /// Given: A CRT credential that that expired 100 second back
    /// When: I convert the credentials to AWSCredentials
    /// Then: I should get a temporary AWSCredentials
    func testExpiredCRTCredentialsToTemporaryAWSCredentialsConversion() throws {
        let credentials = try AwsCommonRuntimeKit.Credentials(
            accessKey: "someaccesskey",
            secret: "somesecret",
            sessionToken: "somesession",
            expiration: Date().addingTimeInterval(-100))
        let awsCredentials = try credentials.toAWSCredentials()
        XCTAssertNotNil(awsCredentials)
        XCTAssertNotNil(awsCredentials as? AWSTemporaryCredentials)
    }
}

struct MockCredentials: AWSTemporaryCredentials {
    let sessionToken: String
    let accessKeyId: String
    let secretAccessKey: String
    let expiration: Date
}
