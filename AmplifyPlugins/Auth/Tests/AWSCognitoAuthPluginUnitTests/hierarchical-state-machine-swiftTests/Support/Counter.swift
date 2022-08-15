//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import HSM

typealias CounterStateMachine = StateMachine<
    Counter.Resolver.StateType,
    CounterEnvironment
>
typealias EffectName = String
typealias TestClosure = (EventDispatcher) -> Void

extension CounterStateMachine {
    static func logging() -> CounterStateMachine {
        CounterStateMachine(
            resolver: Counter.Resolver().logging(),
            environment: CounterEnvironment.empty
        )
    }

    static func `default`() -> CounterStateMachine {
        CounterStateMachine(
            resolver: Counter.Resolver(),
            environment: CounterEnvironment.empty
        )
    }
}

struct Counter: State {
    let type = "Counter"
    let value: Int
}

struct CounterEnvironment: Environment {
    static let empty = CounterEnvironment()
}
