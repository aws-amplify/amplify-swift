//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension SignOutState {
    struct Resolver: StateMachineResolver {
        typealias StateType = SignOutState
        let defaultState = SignOutState.notStarted

        init() { }

        func resolve(
            oldState: SignOutState,
            byApplying event: StateMachineEvent
        ) -> StateResolution<SignOutState> {

            switch oldState {
            case .notStarted:
                guard let signOutEvent = event as? SignOutEvent else {
                    return .from(oldState)
                }
                return resolveNotStarted(byApplying: signOutEvent, from: oldState)
            case .signingOutGlobally:
                guard let signOutEvent = event as? SignOutEvent else {
                    return .from(oldState)
                }
                return resolveSigningOutGlobally(byApplying: signOutEvent, from: oldState)
            case .revokingToken:
                guard let signOutEvent = event as? SignOutEvent else {
                    return .from(oldState)
                }
                return resolveRevokingToken(byApplying: signOutEvent, from: oldState)
            case .signingOutLocally(let signedInData):
                guard let signOutEvent = event as? SignOutEvent else {
                    return .from(oldState)
                }
                return resolveSigningOutLocally(byApplying: signOutEvent,
                                                from: oldState,
                                                signedInData: signedInData)
            case .signingOutHostedUI:
                guard let signOutEvent = event as? SignOutEvent else {
                    return .from(oldState)
                }
                return resolveHostedUISignOut(byApplying: signOutEvent, from: oldState)
            case .signedOut:
                return .from(oldState)
            case .error:
                return .from(oldState)
            }
        }

        private func resolveNotStarted(byApplying signOutEvent: SignOutEvent,
                                       from oldState: SignOutState) -> StateResolution<SignOutState> {
            switch signOutEvent.eventType {
            case .signOutGlobally(let signedInData):
                let action = SignOutGlobally(signedInData: signedInData)
                return StateResolution(
                    newState: SignOutState.signingOutGlobally,
                    actions: [action]
                )
            case .revokeToken(let signedInData):
                let action = RevokeToken(signedInData: signedInData)
                return StateResolution(
                    newState: SignOutState.revokingToken,
                    actions: [action]
                )
            case .invokeHostedUISignOut(let signOutEventData, let signedInData):
                let action = ShowHostedUISignOut(signOutEvent: signOutEventData,
                                                 signInData: signedInData)
                return .init(newState: .signingOutHostedUI, actions: [action])
            case .signOutGuest:
                let action = SignOutLocally()
                return .init(newState: .signingOutLocally(nil),
                             actions: [action])
            default:
                return .from(oldState)
            }
        }

        private func resolveHostedUISignOut(byApplying signOutEvent: SignOutEvent,
                                            from oldState: SignOutState)
        -> StateResolution<SignOutState> {
            switch signOutEvent.eventType {
            case .signOutGlobally(let signedInData):
                let action = SignOutGlobally(signedInData: signedInData)
                return StateResolution(
                    newState: SignOutState.signingOutGlobally,
                    actions: [action]
                )
            case .revokeToken(let signedInData):
                let action = RevokeToken(signedInData: signedInData)
                return StateResolution(
                    newState: SignOutState.revokingToken,
                    actions: [action]
                )
            case .signedOutFailure(let error):
                return .from(.error(error))
            default:
                return .from(oldState)
            }
        }

        private func resolveSigningOutGlobally(byApplying signOutEvent: SignOutEvent,
                                               from oldState: SignOutState) -> StateResolution<SignOutState> {
            switch signOutEvent.eventType {
            case .revokeToken(let signedInData):
                let action = RevokeToken(signedInData: signedInData)
                return StateResolution(
                    newState: SignOutState.revokingToken,
                    actions: [action]
                )
            case .signedOutFailure(let error):
                return .from(.error(error))
            default:
                return .from(oldState)
            }
        }

        private func resolveRevokingToken(byApplying signOutEvent: SignOutEvent,
                                          from oldState: SignOutState) -> StateResolution<SignOutState> {
            switch signOutEvent.eventType {
            case .signOutLocally(let signedInData):
                let action = SignOutLocally()
                return .init(newState: .signingOutLocally(signedInData),
                             actions: [action])
            case .signedOutFailure(let error):
                return .from(.error(error))
            default:
                return .from(oldState)
            }
        }

        private func resolveSigningOutLocally(
            byApplying event: SignOutEvent,
            from oldState: SignOutState,
            signedInData: SignedInData?)
        -> StateResolution<SignOutState> {
            switch event.eventType {
            case .signedOutSuccess:
                let signedOutData = SignedOutData(lastKnownUserName: signedInData?.userName)
                return .from(.signedOut(signedOutData))
            case .signedOutFailure:
                let error = AuthenticationError.unknown(message: "Failed in clearing data from store")
                return .from(.error(error))
            default:
                return .from(oldState)
            }
        }
    }
}
