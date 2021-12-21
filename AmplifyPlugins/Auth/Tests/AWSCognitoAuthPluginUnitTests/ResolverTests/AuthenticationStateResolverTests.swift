//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class AuthenticationStateResolverTests: XCTestCase {

    var resolver: AuthenticationState.Resolver {
        AuthenticationState.Resolver()
    }

    func testInitialState() {
        XCTAssertEqual(resolver.defaultState, .notConfigured)
    }

}
