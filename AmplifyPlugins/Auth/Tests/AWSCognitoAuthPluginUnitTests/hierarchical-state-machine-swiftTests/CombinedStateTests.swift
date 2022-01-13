//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class CombinedStateTests: XCTestCase {

    func testSimpleCombinedState() {
        let starting = ColorCounter(
            color: .red,
            counter: Counter(value: 0),
            hasTriggered: false
        )

        let ending = ColorCounter.Resolver().logging().resolve(
            oldState: starting,
            byApplying: Color.Event.next
        )

        let expected = ColorCounter(
            color: .orange,
            counter: Counter(value: 0),
            hasTriggered: false
        )

        XCTAssertEqual(ending.newState, expected)
    }

    /// As of this writing, this only tests the ColorCounter.Resolver logic, but at
    /// some point, we expect to refactor the resolver logic to automatically apply
    /// combined states. At that point, this will become a meaningful test of the
    /// baked-in resolver's ability to automatically resolve nested/combined states
    func testCombinedCanResolve() {
        let starting = ColorCounter(
            color: .orange,
            counter: Counter(value: 2),
            hasTriggered: false
        )

        let ending = ColorCounter.Resolver().logging().resolve(
            oldState: starting,
            byApplying: Color.Event.next
        )

        let expected = ColorCounter(
            color: .yellow,
            counter: Counter(value: 2),
            hasTriggered: true
        )

        XCTAssertEqual(ending.newState, expected)
    }

}
