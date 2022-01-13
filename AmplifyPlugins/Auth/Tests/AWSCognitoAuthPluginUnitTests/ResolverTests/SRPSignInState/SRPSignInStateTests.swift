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
        let expected = SRPSignInState.signedIn(SignedInData.testData)
        XCTAssertEqual(
            resolver.resolve(
                oldState: oldState,
                byApplying: SRPSignInEvent.finalizeSRPSignInEvent
            ).newState,
            expected
        )
    }

}
