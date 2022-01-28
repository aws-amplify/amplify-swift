//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public extension FetchUserPoolTokensState {

    struct Resolver: StateMachineResolver {
        public typealias StateType = FetchUserPoolTokensState
        public let defaultState = FetchUserPoolTokensState.configuring

        public init() { }

        func resolve(
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
            case .fetched:
                return .from(oldState)
            case .error:
                return .from(oldState)
            }

        }

        private func resolveConfiguringState(
            byApplying fetchUserPoolTokenEvent: FetchUserPoolTokensEvent,
            from oldState: FetchUserPoolTokensState) -> StateResolution<StateType>
        {
                switch fetchUserPoolTokenEvent.eventType {
                case .refresh(let cognitoSession):
                    let newState = FetchUserPoolTokensState.refreshing
                    let command = RefreshUserPoolTokens(cognitoSession: cognitoSession)
                    return .init(newState: newState, commands: [command])
                case .fetched:
                    return .init(newState: FetchUserPoolTokensState.fetched)
                default:
                    return .from(oldState)
                }
        }

        private func resolveRefreshingState(
            byApplying fetchUserPoolTokenEvent: FetchUserPoolTokensEvent,
            from oldState: FetchUserPoolTokensState) -> StateResolution<StateType>
        {
                switch fetchUserPoolTokenEvent.eventType {
                case .fetched:
                    return .init(newState: FetchUserPoolTokensState.fetched)
                case .throwError(let error):
                    return .init(newState: FetchUserPoolTokensState.error(error))
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
