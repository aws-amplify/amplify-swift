//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FetchIdentityState {

    struct Resolver: StateMachineResolver {
        typealias StateType = FetchIdentityState
        let defaultState = FetchIdentityState.configuring

        init() { }

        func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<StateType> {
            guard let fetchIdentityEvent = isFetchIdentityEvent(event) else {
                return .from(oldState)
            }

            switch oldState {
            case .configuring:
                switch fetchIdentityEvent.eventType {
                case .fetch(let cognitoSession):
                    let action = FetchAuthIdentityId(cognitoSession: cognitoSession)
                    return .init(newState: FetchIdentityState.fetching, actions: [action])
                case .fetched:
                    return .init(newState: FetchIdentityState.fetched)
                default:
                    return .from(oldState)
                }
            case .fetching:
                switch fetchIdentityEvent.eventType {
                case .fetched:
                    return .init(newState: FetchIdentityState.fetched, actions: [])
                case .throwError(let error):
                    return .init(newState: FetchIdentityState.error(error))
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
