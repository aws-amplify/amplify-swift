//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class AuthStateConfiguringTests: XCTestCase {
    var resolver: AnyResolver<AuthState> {
        AuthState.Resolver().logging().eraseToAnyResolver()
    }

    let oldState = AuthState.configuringAuth

    func testConfigureFetchCachedCredentialsReceived() {
        let expected = AuthState.waitingForCachedCredentials(AuthConfiguration.testData)
        let resolution = resolver.resolve(oldState: oldState,
                                          byApplying: AuthEvent.fetchCachedCredentials)
        XCTAssertEqual(resolution.newState, expected)
    }

    func testUnSupported() {
        func assertIfUnsupported(_ event: AuthEvent) {
            switch event.eventType {
            case .fetchCachedCredentials:
                // Supported
                break
            default:
                let resolution = resolver.resolve(oldState: oldState, byApplying: event)
                XCTAssertEqual(resolution.newState, oldState)
            }
        }

        AuthEvent.allEvents.forEach(assertIfUnsupported(_:))
    }

}
