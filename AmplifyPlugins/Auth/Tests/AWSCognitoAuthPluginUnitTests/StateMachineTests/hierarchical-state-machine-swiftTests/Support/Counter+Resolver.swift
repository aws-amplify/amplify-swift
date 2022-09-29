//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin

extension Counter {
    struct Resolver: StateMachineResolver {
        typealias StateType = Counter

        var defaultState: StateType { Counter(value: 0) }

        func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<StateType> {
            guard let mockEvent = event as? Counter.Event else {
                return StateResolution(newState: defaultState)
            }
            let resolution = Counter.Resolver.resolveStateType(oldState, byApplying: mockEvent)
            return resolution
        }

        private static func resolveStateType(_ oldState: StateType, byApplying event: Counter.Event) -> StateResolution<StateType> {
            var actions = [Action]()
            var newValue = oldState.value
            switch event.eventType {
            case .decrement:
                newValue -= 1
            case .increment:
                newValue += 1
            case .adjustBy(let value):
                newValue += value
            case .set(let value):
                newValue = value
            case .incrementAndDoActions(let eventActions):
                newValue += 1
                actions.append(contentsOf: eventActions)
            }
            let newState = Counter(value: newValue)
            return StateResolution(newState: newState, actions: actions)
        }
    }
}
