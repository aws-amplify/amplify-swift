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
            case .signingOutHostedUI(let signedInData):
                guard let signOutEvent = event as? SignOutEvent else {
                    return .from(oldState)
                }
                return resolveHostedUISignOut(byApplying: signOutEvent,
                                              signedInData: signedInData,
                                              from: oldState)
            case .buildingRevokeTokenError:
                guard let signOutEvent = event as? SignOutEvent else {
                    return .from(oldState)
                }
                return resolveBuildingRevokeTokenError(byApplying: signOutEvent, from: oldState)
            case .signedOut:
                return .from(oldState)
            case .error:
                return .from(oldState)
            }
        }

        private func resolveNotStarted(
            byApplying signOutEvent: SignOutEvent,
            from oldState: SignOutState) -> StateResolution<SignOutState> {
                switch signOutEvent.eventType {
                case .signOutGlobally(let signedInData, hostedUIError: let hostedUIError):
                    let action = SignOutGlobally(signedInData: signedInData,
                                                 hostedUIError: hostedUIError)
                    return StateResolution(
                        newState: SignOutState.signingOutGlobally,
                        actions: [action]
                    )
                case .revokeToken(let signedInData,
                                  hostedUIError: let hostedUIError,
                                  globalSignOutError: let globalSignOutError):
                    let action = RevokeToken(signedInData: signedInData,
                                             hostedUIError: hostedUIError,
                                             globalSignOutError: globalSignOutError)
                    return StateResolution(
                        newState: SignOutState.revokingToken,
                        actions: [action]
                    )
                case .invokeHostedUISignOut(let signOutEventData, let signedInData):
                    let action = ShowHostedUISignOut(signOutEvent: signOutEventData,
                                                     signInData: signedInData)
                    return .init(newState: .signingOutHostedUI(signedInData), actions: [action])
                case .signOutGuest:
                    let action = SignOutLocally(hostedUIError: nil,
                                                globalSignOutError: nil,
                                                revokeTokenError: nil)
                    return .init(newState: .signingOutLocally(nil),
                                 actions: [action])
                default:
                    return .from(oldState)
                }
            }

        private func resolveHostedUISignOut(byApplying signOutEvent: SignOutEvent,
                                            signedInData: SignedInData,
                                            from oldState: SignOutState)
        -> StateResolution<SignOutState> {
            switch signOutEvent.eventType {
            case .signOutGlobally(let signedInData, hostedUIError: let hostedUIError):
                let action = SignOutGlobally(signedInData: signedInData,
                                             hostedUIError: hostedUIError)
                return StateResolution(
                    newState: SignOutState.signingOutGlobally,
                    actions: [action]
                )
            case .revokeToken(let signedInData,
                              hostedUIError: let hostedUIError,
                              globalSignOutError: let globalSignOutError):
                let action = RevokeToken(signedInData: signedInData,
                                         hostedUIError: hostedUIError,
                                         globalSignOutError: globalSignOutError)
                return StateResolution(
                    newState: SignOutState.revokingToken,
                    actions: [action]
                )
            case .userCancelled:
                let action = CancelSignOut(signedInData: signedInData)
                return .init(newState: .error(.userCancelled), actions: [action])
            default:
                return .from(oldState)
            }
        }

        private func resolveSigningOutGlobally(
            byApplying signOutEvent: SignOutEvent,
            from oldState: SignOutState) -> StateResolution<SignOutState> {
                switch signOutEvent.eventType {
                case .revokeToken(let signedInData,
                                  hostedUIError: let hostedUIError,
                                  globalSignOutError: let globalSignOutError):
                    let action = RevokeToken(signedInData: signedInData,
                                             hostedUIError: hostedUIError,
                                             globalSignOutError: globalSignOutError)
                    return StateResolution(
                        newState: SignOutState.revokingToken,
                        actions: [action]
                    )
                case .globalSignOutError(let signedInData,
                                         globalSignOutError: let globalSignOutError,
                                         hostedUIError: let hostedUIError):
                    let action = BuildRevokeTokenError(signedInData: signedInData,
                                                       hostedUIError: hostedUIError,
                                                       globalSignOutError: globalSignOutError)
                    return .init(newState: .buildingRevokeTokenError,
                                 actions: [action])

                default:
                    return .from(oldState)
                }
            }

        private func resolveRevokingToken(
            byApplying signOutEvent: SignOutEvent,
            from oldState: SignOutState) -> StateResolution<SignOutState> {
                switch signOutEvent.eventType {
                case .signOutLocally(let signedInData,
                                     hostedUIError: let hostedUIError,
                                     globalSignOutError: let globalSignOutError,
                                     revokeTokenError: let revokeTokenError):
                    let action = SignOutLocally(hostedUIError: hostedUIError,
                                                globalSignOutError: globalSignOutError,
                                                revokeTokenError: revokeTokenError)
                    return .init(newState: .signingOutLocally(signedInData),
                                 actions: [action])
                default:
                    return .from(oldState)
                }
            }

        private func resolveBuildingRevokeTokenError (
            byApplying signOutEvent: SignOutEvent,
            from oldState: SignOutState) -> StateResolution<SignOutState> {
                switch signOutEvent.eventType {
                case .signOutLocally(let signedInData,
                                     hostedUIError: let hostedUIError,
                                     globalSignOutError: let globalSignOutError,
                                     revokeTokenError: let revokeTokenError):
                    let action = SignOutLocally(hostedUIError: hostedUIError,
                                                globalSignOutError: globalSignOutError,
                                                revokeTokenError: revokeTokenError)
                    return .init(newState: .signingOutLocally(signedInData),
                                 actions: [action])
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
            case .signedOutSuccess(hostedUIError: let hostedUIError,
                                   globalSignOutError: let globalSignOutError,
                                   revokeTokenError: let revokeTokenError):
                let signedOutData = SignedOutData(
                    lastKnownUserName: signedInData?.userName,
                    hostedUIError: hostedUIError,
                    globalSignOutError: globalSignOutError,
                    revokeTokenError: revokeTokenError
                )
                return .from(.signedOut(signedOutData))
            case .signedOutFailure:
                let action = CancelSignOut(signedInData: signedInData)
                return .init(newState: .error(.localSignOut), actions: [action])
            default:
                return .from(oldState)
            }
        }
    }
}
