//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension CredentialStoreState {

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
            case .loadingStoredCredentials, .storingCredentials, .clearingCredentials:
                return resolveOperationCompletion(oldState: oldState, byApplying: credentialStoreEvent)
            case .idle, error:
                return resolveIdleAndErrorState(oldState: oldState, byApplying: credentialStoreEvent)
            }
        }

        private func resolveNotConfigured(
            byApplying credentialStoreEvent: CredentialStoreEvent
        ) -> StateResolution<StateType> {

            switch credentialStoreEvent.eventType {
            case .migrateLegacyCredentialStore:
                let action = MigrateLegacyCredentialStore()
                let resolution = StateResolution(
                    newState: CredentialStoreState.migratingLegacyStore,
                    actions: [action]
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
            case .loadCredentialStore:
                let action = LoadCredentialStore()
                let resolution = StateResolution(
                    newState: CredentialStoreState.loadingStoredCredentials,
                    actions: [action]
                )
                return resolution
            case .throwError(let error):
                return .init(newState: CredentialStoreState.error(error))
            default:
                return .from(oldState)
            }
        }

        private func resolveOperationCompletion(
            oldState: StateType,
            byApplying credentialStoreEvent: CredentialStoreEvent
        ) -> StateResolution<StateType> {
            switch credentialStoreEvent.eventType {
            case .completedOperation(let storedCredentials):
                return .init(newState: CredentialStoreState.idle(storedCredentials))
            case .throwError(let error):
                return .init(newState: CredentialStoreState.error(error))
            default:
                return .from(oldState)
            }
        }

        private func resolveIdleAndErrorState(
            oldState: StateType,
            byApplying credentialStoreEvent: CredentialStoreEvent
        ) -> StateResolution<StateType> {
            switch credentialStoreEvent.eventType {
            case .loadCredentialStore:
                let action = LoadCredentialStore()
                let resolution = StateResolution(
                    newState: CredentialStoreState.loadingStoredCredentials,
                    actions: [action]
                )
                return resolution
            case .storeCredentials(let credentials):
                let action = StoreCredentials(credentials: credentials)
                let resolution = StateResolution(
                    newState: CredentialStoreState.storingCredentials,
                    actions: [action]
                )
                return resolution
            case .clearCredentialStore:
                let action = ClearCredentialStore()
                let resolution = StateResolution(
                    newState: CredentialStoreState.clearingCredentials,
                    actions: [action]
                )
                return resolution
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
