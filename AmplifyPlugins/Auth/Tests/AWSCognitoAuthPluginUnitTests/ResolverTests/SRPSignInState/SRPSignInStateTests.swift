//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class SRPSignInStateTests: XCTestCase {
    var resolver: AnyResolver<SRPSignInState> {
        SRPSignInState.Resolver().logging().eraseToAnyResolver()
    }

    let oldState = SRPSignInState.respondingPasswordVerifier(SRPStateData.testData)

    func testInitialState() {
        XCTAssertEqual(resolver.defaultState, .notStarted)
    }

    func testSignedIn() {
        let testData = SignedInData.testData
        let event = SignInEvent.finalizeSRPSignInEvent(signedInData: testData)
        let expected = SRPSignInState.signedIn(testData)
        XCTAssertEqual(
            resolver.resolve(
                oldState: oldState,
                byApplying: event
            ).newState,
            expected
        )
    }

}
