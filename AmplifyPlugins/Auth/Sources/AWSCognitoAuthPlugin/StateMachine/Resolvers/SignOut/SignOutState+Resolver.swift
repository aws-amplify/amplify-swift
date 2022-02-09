//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension SignOutState {
    struct Resolver: StateMachineResolver {
        public typealias StateType = SignOutState
        public let defaultState = SignOutState.notStarted

        public init() { }

        func resolve(
            oldState: SignOutState,
            byApplying event: StateMachineEvent
        ) -> StateResolution<SignOutState> {

            guard let signOutEvent = event as? SignOutEvent else {
                return .from(oldState)
            }

            switch oldState {
            case .notStarted:
                return resolveNotStarted(byApplying: signOutEvent, from: oldState)
            case .signingOutGlobally:
                return resolveSigningOutGlobally(byApplying: signOutEvent, from: oldState)
            case .revokingToken:
                return resolveRevokingToken(byApplying: signOutEvent, from: oldState)
            case .signingOutLocally(let signedInData):
                return resolveClearingCredentialStore(byApplying: signOutEvent,
                                                      from: oldState,
                                                      signedInData: signedInData)
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
                return .from(.signingOutLocally(signedInData))
            case .signedOutFailure(let error):
                return .from(.error(error))
            default:
                return .from(oldState)
            }
        }

        private func resolveClearingCredentialStore(byApplying signOutEvent: SignOutEvent,
                                                    from oldState: SignOutState,
                                                    signedInData: SignedInData) -> StateResolution<SignOutState> {
            switch signOutEvent.eventType {
            case .signedOutSuccess:
                let signedOutData = SignedOutData(lastKnownUserName: signedInData.userName)
                return .from(.signedOut(signedOutData))
            case .signedOutFailure(let error):
                return .from(.error(error))
            default:
                return .from(oldState)
            }
        }
    }
}

