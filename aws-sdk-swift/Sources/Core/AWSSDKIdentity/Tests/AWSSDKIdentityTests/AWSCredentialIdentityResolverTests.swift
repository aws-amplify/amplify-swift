//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct AWSSDKIdentity.EnvironmentAWSCredentialIdentityResolver

class AWSCredentialIdentityResolverTests: XCTestCase {
    
    func testGetCRTCredentialsWhenSelfIsBackedByCRT() {
        let subject = try! EnvironmentAWSCredentialIdentityResolver()
        let result = try! subject.getCRTAWSCredentialIdentityResolver()
        XCTAssertIdentical(result, subject.crtAWSCredentialIdentityResolver)
    }
    
    func testGetCRTCredentialsWhenSelfIsNotBackedByCRT() async {
        let subject = MockAWSCredentialIdentityResolver()
        let provider = try! subject.getCRTAWSCredentialIdentityResolver()
        let credentials = try! await provider.getCredentials()
        XCTAssertEqual(credentials.getAccessKey(), "some_access_key")
        XCTAssertEqual(credentials.getSecret(), "some_secret")
    }
}
