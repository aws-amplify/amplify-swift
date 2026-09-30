//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AuthStateNotConfiguredTests: XCTestCase, @unchecked Sendable {
    var resolver: AnyResolver<AuthState> {
        AuthState.Resolver().logging().eraseToAnyResolver()
    }

    let oldState = AuthState.notConfigured

    func testConfigureAuthReceived() {
        let expected = AuthState.configuringAuth
        let resolution = resolver.resolve(oldState: oldState, byApplying: AuthEvent.configureAuth)
        XCTAssertEqual(resolution.newState, expected)
    }

    func testUnSupported() {
        func assertIfUnsupported(_ event: AuthEvent) {
            switch event.eventType {
            case .configureAuth:
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
