//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public extension FetchUserPoolTokensState {

    struct Resolver: StateMachineResolver {
        public typealias StateType = FetchUserPoolTokensState
        public let defaultState = FetchUserPoolTokensState.configuring

        public init() { }

        public func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<StateType> {
            guard let userPoolTokenEvent = isFetchUserPoolTokenEvent(event) else {
                return .from(oldState)
            }
            
            switch oldState {
            case .configuring:
                return resolveConfiguringState(byApplying: userPoolTokenEvent, from: oldState)
            case .refreshing:
                return resolveRefreshingState(byApplying: userPoolTokenEvent, from: oldState)
            case .fetching:
                return resolveFetchingState(byApplying: userPoolTokenEvent, from: oldState)
            case .fetched:
                return .from(oldState)
            case .error:
                return .from(oldState)
            }

        }
        
        private func resolveConfiguringState(
            byApplying fetchUserPoolTokenEvent: FetchUserPoolTokensEvent,
            from oldState: FetchUserPoolTokensState) -> StateResolution<StateType> {
                switch fetchUserPoolTokenEvent.eventType {
                case .fetch:
                    let newState = FetchUserPoolTokensState.fetching
                    let command = FetchUserPoolTokens()
                    return .init(newState: newState, commands: [command])
                case .refresh:
                    let newState = FetchUserPoolTokensState.refreshing
                    let command = RefreshUserPoolTokens()
                    return .init(newState: newState, commands: [command])
                default:
                    return .from(oldState)
                }
        }
        
        private func resolveRefreshingState(
            byApplying fetchUserPoolTokenEvent: FetchUserPoolTokensEvent,
            from oldState: FetchUserPoolTokensState) -> StateResolution<StateType> {
                switch fetchUserPoolTokenEvent.eventType {
                case .fetched:
                    return .init(newState: FetchUserPoolTokensState.fetched)
                default:
                    return .from(oldState)
                }
        }
        
        private func resolveFetchingState(
            byApplying fetchUserPoolTokenEvent: FetchUserPoolTokensEvent,
            from oldState: FetchUserPoolTokensState) -> StateResolution<StateType> {
                switch fetchUserPoolTokenEvent.eventType {
                case .fetched:
                    return .init(newState: FetchUserPoolTokensState.fetched)
                default:
                    return .from(oldState)
                }
        }

                
        private func isFetchUserPoolTokenEvent(_ event: StateMachineEvent) -> FetchUserPoolTokensEvent? {
            guard let userPoolTokenEvent = event as? FetchUserPoolTokensEvent else {
                return nil
            }
            return userPoolTokenEvent
        }

    }
}
