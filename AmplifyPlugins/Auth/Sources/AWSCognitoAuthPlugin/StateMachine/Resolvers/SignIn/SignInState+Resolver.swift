//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

extension SignInState {

    struct Resolver: StateMachineResolver {

        typealias StateType = SignInState
        let defaultState = SignInState.notStarted

        func resolve(
            oldState: SignInState,
            byApplying event: StateMachineEvent)
        -> StateResolution<SignInState> {

            switch oldState {
            case .notStarted:
                if case .initiateSignInWithSRP(let signInEventData, let deviceMetadata) = event.isSignInEvent {
                    let action = StartSRPFlow(
                        signInEventData: signInEventData,
                        deviceMetadata: deviceMetadata)
                    return .init(newState: .signingInWithSRP(.notStarted, signInEventData),
                                 actions: [action])
                }
                if case .initiateCustomSignIn(let signInEventData, let deviceMetadata) = event.isSignInEvent {
                    let action = StartCustomSignInFlow(
                        signInEventData: signInEventData,
                        deviceMetadata: deviceMetadata)
                    return .init(
                        newState: .signingInWithCustom(.notStarted, signInEventData),
                        actions: [action])
                }
                if case .initiateCustomSignInWithSRP(let signInEventData, let deviceMetadata) = event.isSignInEvent {
                    let action = StartSRPFlow(
                        signInEventData: signInEventData,
                        deviceMetadata: deviceMetadata)
                    return .init(newState: .signingInWithSRPCustom(.notStarted, signInEventData),
                                 actions: [action])
                }
                if case .initiateHostedUISignIn(let options) = event.isSignInEvent {
                    let action = InitializeHostedUISignIn(options: options)
                    return .init(newState: .signingInWithHostedUI(.notStarted), actions: [action])
                }
                if case .initiateMigrateAuth(let signInEventData) = event.isSignInEvent {
                    let action = StartMigrateAuthFlow(signInEventData: signInEventData)
                    return .init(newState: .signingInViaMigrateAuth(.notStarted, signInEventData),
                                 actions: [action])
                }
                return .from(oldState)

            case .signingInWithHostedUI(let hostedUIState):

                if case .signInCompleted(let signedInData) = event.isAuthenticationEvent {
                    return .init(newState: .signedIn(signedInData))
                }

                let resolution = HostedUISignInState.Resolver().resolve(oldState: hostedUIState,
                                                                        byApplying: event)
                let newState = SignInState.signingInWithHostedUI(resolution.newState)
                return .init(newState: newState, actions: resolution.actions)

            case .signingInWithSRP(let srpSignInState, let signInEventData):

                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(subState, challenge.challenge.authChallengeType), actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .confirmDevice(let signedInData) = signInEvent.eventType {
                    let action = ConfirmDevice(signedInData: signedInData)
                    return .init(newState: .confirmingDevice,
                                 actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateDeviceSRP(let challengeResponse) = signInEvent.eventType,
                   case .respondingPasswordVerifier(let srpStateData) = srpSignInState {
                    let action = StartDeviceSRPFlow(
                        srpStateData: srpStateData,
                        authResponse: challengeResponse)
                    return .init(newState: .resolvingDeviceSrpa(.notStarted),
                                 actions: [action])
                }

                let resolution = SRPSignInState.Resolver().resolve(oldState: srpSignInState,
                                                                   byApplying: event)
                let signingInWithSRP = SignInState.signingInWithSRP(resolution.newState,
                                                                    signInEventData)
                return .init(newState: signingInWithSRP, actions: resolution.actions)

            case .signingInWithCustom(let customSignInState, let signInEventData):

                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(subState, challenge.challenge.authChallengeType), actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .confirmDevice(let signedInData) = signInEvent.eventType {
                    let action = ConfirmDevice(signedInData: signedInData)
                    return .init(newState: .confirmingDevice,
                                 actions: [action])
                }

                let resolution = CustomSignInState.Resolver().resolve(
                    oldState: customSignInState, byApplying: event)
                let signingInWithCustom = SignInState.signingInWithCustom(
                    resolution.newState, signInEventData)
                return .init(newState: signingInWithCustom, actions: resolution.actions)

            case .signingInViaMigrateAuth(let migrateSignInState, let signInEventData):

                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(subState, challenge.challenge.authChallengeType), actions: [action])
                }

                let resolution = MigrateSignInState.Resolver().resolve(
                    oldState: migrateSignInState, byApplying: event)
                let signingInWithMigration = SignInState.signingInViaMigrateAuth(
                    resolution.newState, signInEventData)
                return .init(newState: signingInWithMigration, actions: resolution.actions)

            case .resolvingChallenge(let challengeState, let challengeType):

                if let signInEvent = event as? SignInEvent,
                   case .confirmDevice(let signedInData) = signInEvent.eventType {
                    let action = ConfirmDevice(signedInData: signedInData)
                    return .init(newState: .confirmingDevice,
                                 actions: [action])
                }

                // This could when we have nested challenges
                // Example newPasswordRequired -> sms_mfa
                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(subState, challenge.challenge.authChallengeType), actions: [action])
                }

                let resolution = SignInChallengeState.Resolver().resolve(
                    oldState: challengeState,
                    byApplying: event)
                return .init(newState: .resolvingChallenge(resolution.newState, challengeType),
                             actions: resolution.actions)

            case .signingInWithSRPCustom(let srpSignInState, let signInEventData):
                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(subState, challenge.challenge.authChallengeType), actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .confirmDevice(let signedInData) = signInEvent.eventType {
                    let action = ConfirmDevice(signedInData: signedInData)
                    return .init(newState: .confirmingDevice,
                                 actions: [action])
                }

                let resolution = SRPSignInState.Resolver().resolve(oldState: srpSignInState,
                                                                   byApplying: event)
                let signingInWithSRP = SignInState.signingInWithSRPCustom(resolution.newState,
                                                                          signInEventData)
                return .init(newState: signingInWithSRP, actions: resolution.actions)
            case .resolvingDeviceSrpa(let deviceSrpState):

                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(subState, challenge.challenge.authChallengeType), actions: [action])
                }

                let resolution = DeviceSRPState.Resolver().resolve(oldState: deviceSrpState,
                                                                   byApplying: event)
                let resolvingDeviceSrpa = SignInState.resolvingDeviceSrpa(resolution.newState)
                return .init(newState: resolvingDeviceSrpa, actions: resolution.actions)

            case .confirmingDevice:

                if case .finalizeSignIn(let signedInData) = event.isSignInEvent {
                    return .init(newState: .signedIn(signedInData),
                                 actions: [SignInComplete(signedInData: signedInData)])
                }
                return .from(oldState)
            case .signedIn, .error:
                return .from(oldState)
            }
        }

    }
}
