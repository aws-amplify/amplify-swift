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

    func testConfigureAuthenticationReceived() {
        let expected = AuthState.configuringAuthentication(.notConfigured)
        let resolution = resolver.resolve(oldState: oldState, byApplying: AuthEvent.configureAuthentication)
        XCTAssertEqual(resolution.newState, expected)
    }

    func testConfigureAuthorizationReceived() {
        let expected = AuthState.configuringAuthorization(.notConfigured, .notConfigured)
        let resolution = resolver.resolve(oldState: oldState, byApplying: AuthEvent.configureAuthorization)
        XCTAssertEqual(resolution.newState, expected)
    }

    func testUnSupported() {
        func assertIfUnsupported(_ event: AuthEvent) {
            switch event.eventType {
            case .configureAuthorization, .configureAuthentication:
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
