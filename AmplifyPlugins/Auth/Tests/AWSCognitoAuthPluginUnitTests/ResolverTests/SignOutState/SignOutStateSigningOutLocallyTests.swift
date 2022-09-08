//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class SignOutStateSigningOutLocallyTests: XCTestCase {

    var resolver: AnyResolver<SignOutState> {
        SignOutState.Resolver().logging().eraseToAnyResolver()
    }

    var oldState = SignOutState.signingOutLocally(.testData)

    func testUnsupported() {
        func assertIfUnsupported(_ event: SignOutEvent) {
            switch event.eventType {
            case .signOutGlobally,
                    .revokeToken,
                    .signOutLocally,
                    .invokeHostedUISignOut,
                    .signOutGuest,
                    .userCancelled,
                    .globalSignOutError:
                XCTAssertEqual(
                    resolver.resolve(
                        oldState: oldState,
                        byApplying: event
                    ).newState,
                    oldState
                )
            case .signedOutSuccess, .signedOutFailure:
                // Supported
                break
            }
        }

        SignOutEvent.allEvents.forEach(assertIfUnsupported(_:))
    }
}
