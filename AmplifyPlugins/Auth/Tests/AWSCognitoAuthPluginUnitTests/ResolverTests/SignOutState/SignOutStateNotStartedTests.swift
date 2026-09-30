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
class SignOutStateNotStartedTests: XCTestCase, @unchecked Sendable {

    var resolver: AnyResolver<SignOutState> {
        SignOutState.Resolver().logging().eraseToAnyResolver()
    }

    var oldState = SignOutState.notStarted

    func testUnsupported() {
        func assertIfUnsupported(_ event: SignOutEvent) {
            switch event.eventType {
            case .signOutLocally,
                    .signedOutSuccess,
                    .signedOutFailure,
                    .hostedUISignOutError,
                    .globalSignOutError:
                XCTAssertEqual(
                    resolver.resolve(
                        oldState: oldState,
                        byApplying: event
                    ).newState,
                    oldState
                )
            case .signOutGlobally,
                    .revokeToken,
                    .invokeHostedUISignOut,
                    .signOutGuest:
                // Supported
                break
            }
        }

        SignOutEvent.allEvents.forEach(assertIfUnsupported(_:))
    }
}
