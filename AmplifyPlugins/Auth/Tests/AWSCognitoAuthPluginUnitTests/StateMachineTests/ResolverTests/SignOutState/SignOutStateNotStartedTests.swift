//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class SignOutStateNotStartedTests: XCTestCase {

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
                    .userCancelled,
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
