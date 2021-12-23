//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin
import hierarchical_state_machine_swift

class AuthStateConfiguringAuthorization: XCTestCase {
    var resolver: AnyResolver<AuthState> {
        AuthState.Resolver().logging().eraseToAnyResolver()
    }

    let oldState = AuthState.configuringAuthorization(.notConfigured, .notConfigured)

    func testAuthorizationConfiguredReceived() {
        let expected = AuthState.configured(.notConfigured, .notConfigured)
        let resolution = resolver.resolve(oldState: oldState, byApplying: AuthEvent.authorizationConfigured)
        XCTAssertEqual(resolution.newState, expected)
    }

    func testUnSupported() {
        func assertIfUnsupported(_ event: AuthEvent) {
            switch event.eventType {
            case .authorizationConfigured:
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
