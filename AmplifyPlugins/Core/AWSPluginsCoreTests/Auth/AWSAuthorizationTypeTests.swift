//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSPluginsCore

class AWSAuthorizationTypeTests: XCTestCase {

    func testRequiresAuthPlugin() {
        XCTAssertFalse(AWSAuthorizationType.apiKey.requiresAuthPlugin)
        XCTAssertFalse(AWSAuthorizationType.none.requiresAuthPlugin)
        XCTAssertFalse(AWSAuthorizationType.openIDConnect.requiresAuthPlugin)
        XCTAssertFalse(AWSAuthorizationType.function.requiresAuthPlugin)
        XCTAssertTrue(AWSAuthorizationType.awsIAM.requiresAuthPlugin)
        XCTAssertTrue(AWSAuthorizationType.amazonCognitoUserPools.requiresAuthPlugin)
    }
}
