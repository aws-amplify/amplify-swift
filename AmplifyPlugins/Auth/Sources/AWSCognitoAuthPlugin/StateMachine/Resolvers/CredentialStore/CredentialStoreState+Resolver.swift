//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension CredentialStoreState {

    struct Resolver: StateMachineResolver {
        typealias StateType = CredentialStoreState
        let defaultState = CredentialStoreState.notConfigured

        init() { }

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
            case .success, .error:
                return resolveSuccessAndErrorState(oldState: oldState, byApplying: credentialStoreEvent)
            case .idle:
                return resolveIdleState(oldState: oldState, byApplying: credentialStoreEvent)
            }
        }

        private func resolveNotConfigured(
            byApplying credentialStoreEvent: CredentialStoreEvent
        ) -> StateResolution<StateType> {

            switch credentialStoreEvent.eventType {
            case .migrateLegacyCredentialStore, .loadCredentialStore:
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
                let action = IdleCredentialStore()
                let resolution = StateResolution(
                    newState: CredentialStoreState.success(storedCredentials),
                    actions: [action]
                )
                return resolution
            case .throwError(let error):
                let action = IdleCredentialStore()
                let resolution = StateResolution(
                    newState: CredentialStoreState.error(error),
                    actions: [action]
                )
                return resolution
            default:
                return .from(oldState)
            }
        }

        private func resolveSuccessAndErrorState(
            oldState: StateType,
            byApplying credentialStoreEvent: CredentialStoreEvent
        ) -> StateResolution<StateType> {
            switch credentialStoreEvent.eventType {
            case .moveToIdleState:
                return .init(newState: CredentialStoreState.idle)
            default:
                return .from(oldState)
            }
        }

        private func resolveIdleState(
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
