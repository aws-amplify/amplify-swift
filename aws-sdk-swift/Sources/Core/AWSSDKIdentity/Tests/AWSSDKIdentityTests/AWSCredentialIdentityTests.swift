//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import class SmithyIdentity.CRTAWSCredentialIdentity
import struct SmithyIdentity.AWSCredentialIdentity

class AWSCredentialIdentityTests: XCTestCase {
    
    let accessKey = "some_access_key"
    let secret = "some_secret"
    let session = "some_session"
    let expiration = Date.init(timeIntervalSince1970: 100)
    
    func testDefaultAWSCredentialIdentityInit() {
        let creds = AWSCredentialIdentity(
            accessKey: accessKey,
            secret: secret
        )
        
        XCTAssertEqual(creds.accessKey, accessKey)
        XCTAssertEqual(creds.secret, secret)
        XCTAssertNil(creds.sessionToken)
        XCTAssertNil(creds.expiration)
    }
    
    func testCRTAWSCredentialIdentity() {
        let crtAWSCredentialIdentity = try! CRTAWSCredentialIdentity(awsCredentialIdentity: .init(
            accessKey: accessKey,
            secret: secret,
            expiration: expiration,
            sessionToken: session
        ))
        let accessKey = crtAWSCredentialIdentity.getAccessKey()
        let secret = crtAWSCredentialIdentity.getSecret()
        let session = crtAWSCredentialIdentity.getSessionToken()
        let expiration = crtAWSCredentialIdentity.getExpiration()
        XCTAssertEqual(accessKey, self.accessKey)
        XCTAssertEqual(secret, self.secret)
        XCTAssertEqual(session, self.session)
        XCTAssertEqual(expiration, self.expiration)
    }
}
