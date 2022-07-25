//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class SignOutStateRevokingTokenTests: XCTestCase {

    var resolver: AnyResolver<SignOutState> {
        SignOutState.Resolver().logging().eraseToAnyResolver()
    }

    var oldState = SignOutState.revokingToken

    func testUnsupported() {
        func assertIfUnsupported(_ event: SignOutEvent) {
            switch event.eventType {
            case .signOutGlobally, .revokeToken, .signedOutSuccess, .invokeHostedUISignOut:
                XCTAssertEqual(
                    resolver.resolve(
                        oldState: oldState,
                        byApplying: event
                    ).newState,
                    oldState
                )
            case .signOutLocally, .signedOutFailure:
                // Supported
                break
            }
        }

        SignOutEvent.allEvents.forEach(assertIfUnsupported(_:))
    }
}
