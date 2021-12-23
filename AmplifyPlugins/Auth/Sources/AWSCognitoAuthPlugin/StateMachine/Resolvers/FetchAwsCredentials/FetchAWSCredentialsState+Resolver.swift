//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public extension FetchAWSCredentialsState {

    struct Resolver: StateMachineResolver {
        public typealias StateType = FetchAWSCredentialsState
        public let defaultState = FetchAWSCredentialsState.configuring

        public init() { }

        public func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<StateType> {
            guard let fetchAWSCredentialEvent = isFetchAWSCredentialEvent(event) else {
                return .from(oldState)
            }
            
            switch oldState {
            case .configuring:
                switch fetchAWSCredentialEvent.eventType {
                case .fetch:
                    let command = FetchAuthAWSCredentials()
                    return .init(newState: FetchAWSCredentialsState.fetching, commands: [command])
                case .refresh:
                    let command = RefreshAWSCredentials()
                    return .init(newState: FetchAWSCredentialsState.refreshing, commands: [command])
                default:
                    return .from(oldState)
                }
            case .refreshing:
                switch fetchAWSCredentialEvent.eventType {
                case .fetched:
                    return .init(newState: FetchAWSCredentialsState.fetched)
                default:
                    return .from(oldState)
                }
            case .fetching:
                switch fetchAWSCredentialEvent.eventType {
                case .fetched:
                    return .init(newState: FetchAWSCredentialsState.fetched)
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
