//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class NotStartedTests: XCTestCase {
    var resolver: AnyResolver<SRPSignInState> {
        SRPSignInState.Resolver().logging().eraseToAnyResolver()
    }

    var oldState = SRPSignInState.notStarted

    func testInvoked() {
        let expected = SRPSignInState.initiatingSRPA(SignInEventData.testData)
        XCTAssertEqual(
            resolver.resolve(
                oldState: oldState,
                byApplying: SignInEvent.initiateSRPEvent
            ).newState,
            expected
        )
    }

    func testError() {
        let expected = SRPSignInState.error(.testData)
        XCTAssertEqual(
            resolver.resolve(
                oldState: oldState,
                byApplying: SignInEvent.authErrorEvent
            ).newState,
            expected
        )
    }

    func testUnsupported() {
        func assertIfUnsupported(_ event: SignInEvent) {
            print(event)
            switch event.eventType {
            case .initiateSRP, .throwAuthError, .throwPasswordVerifierError:
                // Supported
                break
            default:
                XCTAssertEqual(
                    resolver.resolve(
                        oldState: oldState,
                        byApplying: event
                    ).newState,
                    oldState,
                    "Should not support \(event) for oldState \(oldState)"
                )
            }
        }

        SignInEvent.allStates.forEach(assertIfUnsupported(_:))
    }

}
