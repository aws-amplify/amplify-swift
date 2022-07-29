//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DeviceSRPState {
    struct Resolver: StateMachineResolver {
        typealias StateType = DeviceSRPState
        let defaultState = DeviceSRPState.notStarted

        func resolve(
            oldState: DeviceSRPState,
            byApplying event: StateMachineEvent
        ) -> StateResolution<DeviceSRPState> {

            guard let deviceSrpSignInEvent = event as? SignInEvent else {
                return .from(oldState)
            }

            if case .throwAuthError(let authError) = deviceSrpSignInEvent.eventType {
                return errorState(authError)
            }

            if case .throwPasswordVerifierError(let authError) = deviceSrpSignInEvent.eventType {
                return errorState(authError)
            }

            switch oldState {
            case .notStarted:
                return resolveNotStarted(byApplying: deviceSrpSignInEvent)
            case .initiatingDeviceSRPA(let srpStateData):
                return resolveRespondingDeviceSRPA(
                    byApplying: deviceSrpSignInEvent,
                    from: oldState)
            case .respondingDevicePasswordVerifier(let srpStateData):
                return resolveRespondingVerifyPassword(
                    srpStateData: srpStateData,
                    byApplying: deviceSrpSignInEvent)
            case .signedIn, .error:
                return .from(oldState)
            case .cancelling:
                return .from(.notStarted)
            }
        }

        private func resolveNotStarted(
            byApplying signInEvent: SignInEvent) -> StateResolution<DeviceSRPState> {
                switch signInEvent.eventType {
                case .respondDeviceSRPChallenge(let srpStateData, let authResponse):
                    let action = InitiateAuthDeviceSRP(
                        username: srpStateData.username,
                        deviceMetadata: srpStateData.deviceMetadata,
                        authResponse: authResponse)
                    return StateResolution(
                        newState: DeviceSRPState.initiatingDeviceSRPA(srpStateData),
                        actions: [action]
                    )
                default:
                    return .from(.notStarted)
                }
            }

        private func resolveRespondingDeviceSRPA(
            byApplying signInEvent: SignInEvent,
            from oldState: DeviceSRPState)
        -> StateResolution<DeviceSRPState> {
            switch signInEvent.eventType {
            case .respondDevicePasswordVerifier(let srpStateData, let authResponse):
                let action = VerifyDevicePasswordSRP(
                    stateData: srpStateData,
                    authResponse: authResponse)
                return StateResolution(
                    newState: DeviceSRPState.respondingDevicePasswordVerifier(srpStateData),
                    actions: [action]
                )
            case .cancelSRPSignIn:
                return .from(.cancelling)
            default:
                return .from(oldState)
            }
        }

        private func resolveRespondingVerifyPassword(
            srpStateData: SRPStateData,
            byApplying signInEvent: SignInEvent)
        -> StateResolution<DeviceSRPState> {
            switch signInEvent.eventType {
            case .finalizeSignIn(let signedInData):
                return .init(newState: .signedIn(signedInData),
                             actions: [SignInComplete(signedInData: signedInData)])
            case .cancelSRPSignIn:
                return .from(.cancelling)
            default:
                return .from(.respondingDevicePasswordVerifier(srpStateData))
            }
        }

        private func errorState(_ error: SignInError)
        -> StateResolution<DeviceSRPState> {
            let action = CancelSignIn()
            return StateResolution(
                newState: DeviceSRPState.error(error),
                actions: [action]
            )
        }

    }
}
