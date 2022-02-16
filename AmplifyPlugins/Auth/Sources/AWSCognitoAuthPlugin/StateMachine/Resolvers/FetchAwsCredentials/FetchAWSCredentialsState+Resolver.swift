//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FetchAWSCredentialsState {

    struct Resolver: StateMachineResolver {
        typealias StateType = FetchAWSCredentialsState
        let defaultState = FetchAWSCredentialsState.configuring

        init() { }

        func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<StateType> {
            guard let fetchAWSCredentialEvent = isFetchAWSCredentialEvent(event) else {
                return .from(oldState)
            }

            switch oldState {
            case .configuring:
                switch fetchAWSCredentialEvent.eventType {
                case .fetch(let cognitoSession):
                    let action = FetchAuthAWSCredentials(cognitoSession: cognitoSession)
                    return .init(newState: FetchAWSCredentialsState.fetching, actions: [action])
                case .fetched:
                    return .init(newState: .fetched)
                default:
                    return .from(oldState)
                }
            case .fetching:
                switch fetchAWSCredentialEvent.eventType {
                case .fetched:
                    return .init(newState: FetchAWSCredentialsState.fetched)
                case .throwError(let authorizationError):
                    return .init(newState: .error(authorizationError))
                default:
                    return .from(oldState)
                }
            case .fetched:
                return .from(oldState)
            case .error:
                return .from(oldState)
            }
        }

        private func isFetchAWSCredentialEvent(_ event: StateMachineEvent) -> FetchAWSCredentialEvent? {
            guard let fetchAWSCredentialEvent = event as? FetchAWSCredentialEvent else {
                return nil
            }
            return fetchAWSCredentialEvent
        }

    }
}
