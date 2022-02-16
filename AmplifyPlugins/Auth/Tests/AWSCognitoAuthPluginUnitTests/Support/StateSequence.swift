//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

struct StateSequence<MyState, MyEvent>: CustomStringConvertible where MyState: State, MyEvent: StateMachineEvent {
    let resolver: AnyResolver<MyState>
    let oldState: MyState
    let event: MyEvent
    let expected: MyState

    init(resolver: AnyResolver<MyState>,
         oldState: MyState,
         event: MyEvent,
         expected: MyState
    ) {
        self.resolver = resolver
        self.oldState = oldState
        self.event = event
        self.expected = expected
    }

    var description: String {
        "Resolving \(oldState) by applying \(event.type) expecting \(expected)"
    }

    func resolve() -> MyState {
        resolver.resolve(oldState: oldState, byApplying: event).newState
    }

    func assertResolvesToExpected(file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(resolve(), expected, "\(self)", file: file, line: line)
    }

    func assertNotResolvesToExpected(file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotEqual(resolve(), expected, "\(self)", file: file, line: line)
    }
}
