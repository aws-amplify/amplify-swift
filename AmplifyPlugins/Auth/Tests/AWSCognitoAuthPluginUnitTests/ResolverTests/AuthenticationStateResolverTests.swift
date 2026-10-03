//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AuthenticationStateResolverTests: XCTestCase, @unchecked Sendable {

    var resolver: AuthenticationState.Resolver {
        AuthenticationState.Resolver(logger: AmplifyEngineLogRouter())
    }

    func testInitialState() {
        XCTAssertEqual(resolver.defaultState, .notConfigured)
    }

}
