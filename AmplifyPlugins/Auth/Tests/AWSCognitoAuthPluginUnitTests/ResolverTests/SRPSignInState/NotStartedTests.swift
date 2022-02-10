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
                byApplying: SRPSignInEvent.initiateSRPEvent
            ).newState,
            expected
        )
    }

    func testError() {
        let expected = SRPSignInState.error(.testData)
        XCTAssertEqual(
            resolver.resolve(
                oldState: oldState,
                byApplying: SRPSignInEvent.authErrorEvent
            ).newState,
            expected
        )
    }

    func testUnsupported() {
        func assertIfUnsupported(_ event: SRPSignInEvent) {
            print(event)
            switch event.eventType {
            case .finalizeSRPSignIn, .respondNextAuthChallenge, .respondPasswordVerifier,
                    .cancelSRPSignIn, .restoreToNotInitialized:
                XCTAssertEqual(
                    resolver.resolve(
                        oldState: oldState,
                        byApplying: event
                    ).newState,
                    oldState,
                    "Should not support \(event) for oldState \(oldState)"
                )
            case .initiateSRP, .throwAuthError, .throwPasswordVerifierError:
                // Supported
                break
            }
        }

        SRPSignInEvent.allStates.forEach(assertIfUnsupported(_:))
    }

}
