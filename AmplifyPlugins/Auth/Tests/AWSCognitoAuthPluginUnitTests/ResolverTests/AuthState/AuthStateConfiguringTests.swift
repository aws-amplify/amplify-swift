//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin
import hierarchical_state_machine_swift

class AuthStateConfiguringTests: XCTestCase {
    var resolver: AnyResolver<AuthState> {
        AuthState.Resolver().logging().eraseToAnyResolver()
    }

    let oldState = AuthState.configuring

    func testConfigureAuthenticationReceived() {
        let expected = AuthState.configuringAuthentication(.notConfigured)
        let resolution = resolver.resolve(oldState: oldState, byApplying: AuthEvent.configureAuthentication)
        XCTAssertEqual(resolution.newState, expected)
    }

    func testConfigureAuthorizationReceived() {
        let expected = AuthState.configuringAuthorization(.notConfigured, .unconfigured)
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
