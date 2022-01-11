//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public extension FetchIdentityState {

    struct Resolver: StateMachineResolver {
        public typealias StateType = FetchIdentityState
        public let defaultState = FetchIdentityState.configuring

        public init() { }

        public func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<StateType> {
            guard let fetchIdentityEvent = isFetchIdentityEvent(event) else {
                return .from(oldState)
            }

            switch oldState {
            case .configuring:
                switch fetchIdentityEvent.eventType {
                case .fetch:
                    let command = FetchAuthIdentityId()
                    return .init(newState: FetchIdentityState.fetching, commands: [command])
                default:
                    return .from(oldState)
                }
            case .fetching:
                switch fetchIdentityEvent.eventType {
                case .fetched:
                    return .init(newState: FetchIdentityState.fetched, commands: [])
                default:
                    return .from(oldState)
                }
            case .fetched:
                return .from(oldState)
            case .error:
                return .from(oldState)
            }
        }

        private func isFetchIdentityEvent(_ event: StateMachineEvent) -> FetchIdentityEvent? {
            guard let fetchIdentityEvent = event as? FetchIdentityEvent else {
                return nil
            }
            return fetchIdentityEvent
        }

    }
}
