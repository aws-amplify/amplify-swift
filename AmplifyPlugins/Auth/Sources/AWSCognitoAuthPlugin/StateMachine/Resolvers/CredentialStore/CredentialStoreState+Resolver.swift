//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public extension CredentialStoreState {

    struct Resolver: StateMachineResolver {
        public typealias StateType = CredentialStoreState
        public let defaultState = CredentialStoreState.notConfigured

        public init() { }

        func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<StateType> {
            guard let credentialStoreEvent = isCredentialStoreEvent(event) else {
                return .from(oldState)
            }
            switch oldState {
            case .notConfigured:
                return resolveNotConfigured(byApplying: credentialStoreEvent)
            case .migratingLegacyStore:
                return resolveMigratingLegacyStore(oldState: oldState, byApplying: credentialStoreEvent)
            case .loadingStoredCredentials:
                return resolveLoadingStoredCredentials(oldState: oldState, byApplying: credentialStoreEvent)
            default:
                return .from(oldState)
            }
        }

        private func resolveNotConfigured(
            byApplying credentialStoreEvent: CredentialStoreEvent
        ) -> StateResolution<StateType> {

            switch credentialStoreEvent.eventType {
            case .migrateLegacyCredentialStore(let authConfig):
                let command = MigrateLegacyCredentialStore(authConfiguration: authConfig)
                let resolution = StateResolution(
                    newState: CredentialStoreState.migratingLegacyStore(authConfig),
                    commands: [command]
                )
                return resolution
            default:
                return .from(.notConfigured)
            }
        }

        private func resolveMigratingLegacyStore(
            oldState: StateType,
            byApplying credentialStoreEvent: CredentialStoreEvent
        ) -> StateResolution<StateType> {

            switch credentialStoreEvent.eventType {
            case .loadCredentialStore(let authConfig):
                let command = LoadCredentialStore(authConfiguration: authConfig)
                let resolution = StateResolution(
                    newState: CredentialStoreState.loadingStoredCredentials(authConfig),
                    commands: [command]
                )
                return resolution
            default:
                return .from(oldState)
            }
        }

        private func resolveLoadingStoredCredentials(
            oldState: StateType,
            byApplying credentialStoreEvent: CredentialStoreEvent
        ) -> StateResolution<StateType> {
            switch credentialStoreEvent.eventType {
            case .successfullyLoadedCredentialStore(let authConfig):
                return .init(newState: CredentialStoreState.configuredCredentialStore)
            default:
                return .from(oldState)
            }
        }

        private func isCredentialStoreEvent(_ event: StateMachineEvent) -> CredentialStoreEvent? {
            guard let credentialStore = event as? CredentialStoreEvent else {
                return nil
            }
            return credentialStore
        }

    }
}
