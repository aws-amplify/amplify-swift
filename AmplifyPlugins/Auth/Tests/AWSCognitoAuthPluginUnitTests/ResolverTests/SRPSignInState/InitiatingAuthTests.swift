//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

import AWSCognitoIdentityProvider

class InitiatingAuthTests: XCTestCase {
    var resolver: AnyResolver<SRPSignInState> {
        SRPSignInState.Resolver().logging().eraseToAnyResolver()
    }

    let oldState = SRPSignInState.initiatingSRPA(SignInEventData.testData)

    func testInitiateAuthResponseReceived() {
        let expected = SRPSignInState.respondingPasswordVerifier(SRPStateData.testData)
        XCTAssertEqual(
            resolver.resolve(
                oldState: oldState,
                byApplying: SignInEvent.respondPasswordVerifierEvent
            ).newState,
            expected
        )
    }

    func testError() {
        let expected = SRPSignInState.error(.testData)
        let newState = resolver.resolve(
            oldState: oldState,
            byApplying: SignInEvent.authErrorEvent
        ).newState
        XCTAssertEqual(
            newState,
            expected
        )
    }

    func testUnsupported() {
        func assertIfUnsupported(_ event: SignInEvent) {
            switch event.eventType {
            case .initiateSRP, .finalizeSRPSignIn, .respondNextAuthChallenge,
                .restoreToNotInitialized:
                XCTAssertEqual(
                    resolver.resolve(
                        oldState: oldState,
                        byApplying: event
                    ).newState,
                    oldState,
                    "Should not support \(event) for oldState \(oldState)"
                )
            case .respondPasswordVerifier, .cancelSRPSignIn, .throwAuthError,
                    .throwPasswordVerifierError:
                // Supported
                break
            }
        }

        SignInEvent.allStates.forEach(assertIfUnsupported(_:))
    }

}
