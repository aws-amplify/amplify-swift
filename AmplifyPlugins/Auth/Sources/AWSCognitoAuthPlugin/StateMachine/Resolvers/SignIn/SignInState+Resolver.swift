//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

// swiftlint:disable type_body_length
extension SignInState {

    // swiftlint:disable:next nesting
    struct Resolver: StateMachineResolver {

        typealias StateType = SignInState
        let defaultState = SignInState.notStarted

        // swiftlint:disable:next cyclomatic_complexity function_body_length
        func resolve(
            oldState: SignInState,
            byApplying event: StateMachineEvent)
        -> StateResolution<SignInState> {

            switch oldState {
            case .notStarted:
                if case .initiateSignInWithSRP(let signInEventData, let deviceMetadata, let respondToAuthChallenge) = event.isSignInEvent {
                    let action = StartSRPFlow(
                        signInEventData: signInEventData,
                        deviceMetadata: deviceMetadata,
                        respondToAuthChallenge: respondToAuthChallenge)
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
                        deviceMetadata: deviceMetadata,
                        respondToAuthChallenge: nil)
                    return .init(newState: .signingInWithSRPCustom(.notStarted, signInEventData),
                                 actions: [action])
                }
                if case .initiateHostedUISignIn(let options) = event.isSignInEvent {
                    let action = InitializeHostedUISignIn(options: options)
                    return .init(newState: .signingInWithHostedUI(.notStarted), actions: [action])
                }
                if case .initiateMigrateAuth(let signInEventData, let deviceMetadata, let respondToAuthChallenge) = event.isSignInEvent {
                    let action = StartMigrateAuthFlow(
                        signInEventData: signInEventData,
                        deviceMetadata: deviceMetadata,
                        respondToAuthChallenge: respondToAuthChallenge)
                    return .init(newState: .signingInViaMigrateAuth(.notStarted, signInEventData),
                                 actions: [action])
                }
                if case .initiateUserAuth(let signInEventData, let deviceMetadata) = event.isSignInEvent {
                    let action = InitiateUserAuth(
                        signInEventData: signInEventData,
                        deviceMetadata: deviceMetadata)
                    return .init(newState: .signingInWithUserAuth(signInEventData),
                                 actions: [action])
                }
                if case .initiateAutoSignIn(let signInEventData, let deviceMetadata) = event.isSignInEvent {
                    let action = AutoSignIn(
                        signInEventData: signInEventData,
                        deviceMetadata: deviceMetadata)
                    return .init(newState: .autoSigningIn(signInEventData),
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
                let signInMethod = SignInMethod.apiBased(.userSRP)
                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge,
                                                            signInMethod: signInMethod)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState:
                            .resolvingChallenge(
                                subState,
                                challenge.challenge.authChallengeType,
                                signInMethod
                            ), actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .confirmDevice(let signedInData) = signInEvent.eventType {
                    let action = ConfirmDevice(signedInData: signedInData)
                    return .init(newState: .confirmingDevice,
                                 actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateDeviceSRP(let username, let challengeResponse) = signInEvent.eventType,
                   case .respondingPasswordVerifier = srpSignInState {
                    let action = StartDeviceSRPFlow(
                        username: username,
                        authResponse: challengeResponse)
                    return .init(newState: .resolvingDeviceSrpa(.notStarted),
                                 actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateTOTPSetup(_, let challengeResponse) = signInEvent.eventType {
                    let action = InitializeTOTPSetup(
                        authResponse: challengeResponse)
                    return .init(newState: .resolvingTOTPSetup(.notStarted, signInEventData),
                                 actions: [action])
                }

                let resolution = SRPSignInState.Resolver().resolve(oldState: srpSignInState,
                                                                   byApplying: event)
                let signingInWithSRP = SignInState.signingInWithSRP(resolution.newState,
                                                                    signInEventData)
                return .init(newState: signingInWithSRP, actions: resolution.actions)

            case .signingInWithCustom(let customSignInState, let signInEventData):
                let signInMethod = SignInMethod.apiBased(.customWithoutSRP)
                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge,
                                                            signInMethod: signInMethod)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(
                        subState,
                        challenge.challenge.authChallengeType,
                        signInMethod
                    ), actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .confirmDevice(let signedInData) = signInEvent.eventType {
                    let action = ConfirmDevice(signedInData: signedInData)
                    return .init(newState: .confirmingDevice,
                                 actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateDeviceSRP(let username, let challengeResponse) = signInEvent.eventType {
                    let action = StartDeviceSRPFlow(
                        username: username,
                        authResponse: challengeResponse)
                    return .init(newState: .resolvingDeviceSrpa(.notStarted),
                                 actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateTOTPSetup(_, let challengeResponse) = signInEvent.eventType {
                    let action = InitializeTOTPSetup(
                        authResponse: challengeResponse)
                    return .init(newState: .resolvingTOTPSetup(.notStarted, signInEventData),
                                 actions: [action])
                }

                let resolution = CustomSignInState.Resolver().resolve(
                    oldState: customSignInState, byApplying: event)
                let signingInWithCustom = SignInState.signingInWithCustom(
                    resolution.newState, signInEventData)
                return .init(newState: signingInWithCustom, actions: resolution.actions)

            case .signingInViaMigrateAuth(let migrateSignInState, let signInEventData):
                let signInMethod = SignInMethod.apiBased(.userPassword)
                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge,
                                                            signInMethod: signInMethod)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(
                        subState,
                        challenge.challenge.authChallengeType,
                        signInMethod), actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .confirmDevice(let signedInData) = signInEvent.eventType {
                    let action = ConfirmDevice(signedInData: signedInData)
                    return .init(newState: .confirmingDevice,
                                 actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateDeviceSRP(let username, let challengeResponse) = signInEvent.eventType,
                   case .signingIn = migrateSignInState {
                    let action = StartDeviceSRPFlow(
                        username: username,
                        authResponse: challengeResponse)
                    return .init(newState: .resolvingDeviceSrpa(.notStarted),
                                 actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateTOTPSetup(_, let challengeResponse) = signInEvent.eventType {
                    let action = InitializeTOTPSetup(
                        authResponse: challengeResponse)
                    return .init(newState: .resolvingTOTPSetup(.notStarted, signInEventData),
                                 actions: [action])
                }

                let resolution = MigrateSignInState.Resolver().resolve(
                    oldState: migrateSignInState, byApplying: event)
                let signingInWithMigration = SignInState.signingInViaMigrateAuth(
                    resolution.newState, signInEventData)
                return .init(newState: signingInWithMigration, actions: resolution.actions)

            case .resolvingChallenge(let challengeState, let challengeType, let signInMethod):

                if let signInEvent = event as? SignInEvent,
                   case .confirmDevice(let signedInData) = signInEvent.eventType {
                    let action = ConfirmDevice(signedInData: signedInData)
                    return .init(newState: .confirmingDevice,
                                 actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateDeviceSRP(let username, let challengeResponse) = signInEvent.eventType {
                    let action = StartDeviceSRPFlow(
                        username: username,
                        authResponse: challengeResponse)
                    return .init(newState: .resolvingDeviceSrpa(.notStarted),
                                 actions: [action])
                }

                if case .initiateSignInWithSRP(let signInEventData, let deviceMetadata, let respondToAuthChallenge) = event.isSignInEvent {
                    let action = StartSRPFlow(
                        signInEventData: signInEventData,
                        deviceMetadata: deviceMetadata,
                        respondToAuthChallenge: respondToAuthChallenge)
                    return .init(newState: .signingInWithSRP(.notStarted, signInEventData),
                                 actions: [action])
                }

                if case .initiateMigrateAuth(let signInEventData, let deviceMetadata, let respondToAuthChallenge) = event.isSignInEvent {
                    let action = StartMigrateAuthFlow(
                        signInEventData: signInEventData,
                        deviceMetadata: deviceMetadata,
                        respondToAuthChallenge: respondToAuthChallenge)
                    return .init(newState: .signingInViaMigrateAuth(.notStarted, signInEventData),
                                 actions: [action])
                }

                // This could happen when we have nested challenges
                // Example newPasswordRequired -> sms_mfa
                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge,
                                                            signInMethod: signInMethod)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(
                        subState,
                        challenge.challenge.authChallengeType,
                        signInMethod), actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateTOTPSetup(let username, let challengeResponse) = signInEvent.eventType {
                    let action = InitializeTOTPSetup(
                        authResponse: challengeResponse)
                    return .init(
                        newState: .resolvingTOTPSetup(
                            .notStarted,
                            .init(username: username,
                                  password: nil,
                                  signInMethod: signInMethod)),
                        actions: [action])
                }

            #if os(iOS) || os(macOS) || os(visionOS)
                if let signInEvent = event as? SignInEvent,
                   case .initiateWebAuthnSignIn(let data, let respondToAuthChallenge) = signInEvent.eventType {
                    let action = InitializeWebAuthn(
                        username: data.username,
                        respondToAuthChallenge: respondToAuthChallenge,
                        presentationAnchor: data.presentationAnchor
                    )
                    let subState = WebAuthnSignInState.notStarted
                    return .init(newState: .signingInWithWebAuthn(
                        subState
                    ), actions: [action])
                }
            #endif

                let resolution = SignInChallengeState.Resolver().resolve(
                    oldState: challengeState,
                    byApplying: event)
                return .init(newState: .resolvingChallenge(
                    resolution.newState,
                    challengeType,
                    signInMethod), actions: resolution.actions)

            case .signingInWithSRPCustom(let srpSignInState, let signInEventData):
                let signInMethod = SignInMethod.apiBased(.customWithSRP)
                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge,
                                                            signInMethod: signInMethod)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(
                        subState,
                        challenge.challenge.authChallengeType,
                        signInMethod
                    ), actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateDeviceSRP(let username, let challengeResponse) = signInEvent.eventType {
                    let action = StartDeviceSRPFlow(
                        username: username,
                        authResponse: challengeResponse)
                    return .init(newState: .resolvingDeviceSrpa(.notStarted),
                                 actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateTOTPSetup(_, let challengeResponse) = signInEvent.eventType {
                    let action = InitializeTOTPSetup(
                        authResponse: challengeResponse)
                    return .init(newState: .resolvingTOTPSetup(.notStarted, signInEventData),
                                 actions: [action])
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

            case .resolvingTOTPSetup(let setUpTOTPState, let signInEventData):

                if case .finalizeSignIn(let signedInData) = event.isSignInEvent {
                    return .init(newState: .signedIn(signedInData),
                                 actions: [SignInComplete(signedInData: signedInData)])
                }

                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge,
                                                            signInMethod: signInEventData.signInMethod)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(
                        subState,
                        challenge.challenge.authChallengeType,
                        signInEventData.signInMethod
                    ), actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .confirmDevice(let signedInData) = signInEvent.eventType {
                    let action = ConfirmDevice(signedInData: signedInData)
                    return .init(newState: .confirmingDevice,
                                 actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateDeviceSRP(let username, let challengeResponse) = signInEvent.eventType {
                    let action = StartDeviceSRPFlow(
                        username: username,
                        authResponse: challengeResponse)
                    return .init(newState: .resolvingDeviceSrpa(.notStarted),
                                 actions: [action])
                }

                let resolution = SignInTOTPSetupState.Resolver(
                    signInEventData: signInEventData).resolve(
                        oldState: setUpTOTPState,
                        byApplying: event)
                let settingUpTOTPState = SignInState.resolvingTOTPSetup(
                    resolution.newState,
                    signInEventData)
                return .init(newState: settingUpTOTPState, actions: resolution.actions)

            case .resolvingDeviceSrpa(let deviceSrpState):
                let signInMethod = SignInMethod.apiBased(.userSRP)
                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge,
                                                            signInMethod: signInMethod)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(
                        subState,
                        challenge.challenge.authChallengeType,
                        signInMethod), actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateTOTPSetup(let username, let challengeResponse) = signInEvent.eventType {
                    let action = InitializeTOTPSetup(
                        authResponse: challengeResponse)
                    return .init(newState:
                            .resolvingTOTPSetup(
                                .notStarted,
                                .init(username: username,
                                      password: nil,
                                      signInMethod: signInMethod)),
                                 actions: [action])
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
            case .signingInWithUserAuth(let signInEventData):
                if case .finalizeSignIn(let signedInData) = event.isSignInEvent {
                    return .init(newState: .signedIn(signedInData),
                                 actions: [SignInComplete(signedInData: signedInData)])
                }

                if let signInEvent = event as? SignInEvent,
                   case .confirmDevice(let signedInData) = signInEvent.eventType {
                    let action = ConfirmDevice(signedInData: signedInData)
                    return .init(newState: .confirmingDevice,
                                 actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .initiateDeviceSRP(let username, let challengeResponse) = signInEvent.eventType {
                    let action = StartDeviceSRPFlow(
                        username: username,
                        authResponse: challengeResponse)
                    return .init(newState: .resolvingDeviceSrpa(.notStarted),
                                 actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .receivedChallenge(let challenge) = signInEvent.eventType {
                    let action = InitializeResolveChallenge(challenge: challenge,
                                                            signInMethod: signInEventData.signInMethod)
                    let subState = SignInChallengeState.notStarted
                    return .init(newState: .resolvingChallenge(
                        subState,
                        challenge.challenge.authChallengeType,
                        signInEventData.signInMethod
                    ), actions: [action])
                }

            #if os(iOS) || os(macOS) || os(visionOS)
                if let signInEvent = event as? SignInEvent,
                   case .initiateWebAuthnSignIn(let data, let respondToAuthChallenge) = signInEvent.eventType {
                    let action = InitializeWebAuthn(
                        username: data.username,
                        respondToAuthChallenge: respondToAuthChallenge,
                        presentationAnchor: data.presentationAnchor
                    )
                    let subState = WebAuthnSignInState.notStarted
                    return .init(
                        newState: .signingInWithWebAuthn(subState),
                        actions: [action]
                    )
                }
            #endif

                if case .respondPasswordVerifier(let srpStateData, let authResponse, let clientMetadata) = event.isSignInEvent {
                    let action = VerifyPasswordSRP(
                        stateData: srpStateData,
                        authResponse: authResponse,
                        clientMetadata: clientMetadata)
                    return .init(
                        newState: .signingInWithSRP(
                            .respondingPasswordVerifier(srpStateData),
                            signInEventData),
                        actions: [action])
                }

                if let signInEvent = event as? SignInEvent,
                   case .throwAuthError(let error) = signInEvent.eventType {
                    let action = ThrowSignInError(error: error)
                    return StateResolution(
                        newState: .error,
                        actions: [action])

                }
                return .from(oldState)
            case .signingInWithWebAuthn(let webAuthnState):
            #if os(iOS) || os(macOS) || os(visionOS)
                if #available(iOS 17.4, macOS 13.5, *) {
                    if case .throwAuthError(let error) = event.isSignInEvent {
                        let action = ThrowSignInError(error: error)
                        return .init(
                            newState: .error,
                            actions: [action]
                        )
                    }

                    if case .initiateWebAuthnSignIn(let data, let respondToAuthChallenge) = event.isSignInEvent {
                        let action = InitializeWebAuthn(
                            username: data.username,
                            respondToAuthChallenge: respondToAuthChallenge,
                            presentationAnchor: data.presentationAnchor
                        )
                        return .init(
                            newState: .signingInWithWebAuthn(.notStarted),
                            actions: [action]
                        )
                    }

                    let resolution = WebAuthnSignInState.Resolver().resolve(
                        oldState: webAuthnState,
                        byApplying: event
                    )
                    return .init(
                        newState: .signingInWithWebAuthn(resolution.newState),
                        actions: resolution.actions
                    )
                } else {
                    // "WebAuthn is not supported in this OS version
                    // It should technically never happen.
                    let error = SignInError.unknown(message: "WebAuthn is not supported in this OS version")
                    return .init(
                        newState: .error,
                        actions: [ThrowSignInError(error: error)]
                    )
                }
            #else
                let error = SignInError.unknown(message: "WebAuthn is only supported in iOS and macOS")
                return .init(
                    newState: .error,
                    actions: [ThrowSignInError(error: error)]
                )
            #endif
            case .autoSigningIn:
                if case .finalizeSignIn(let signedInData) = event.isSignInEvent {
                    return .init(newState: .signedIn(signedInData),
                                 actions: [SignInComplete(signedInData: signedInData)])
                }
                
                if let signInEvent = event as? SignInEvent,
                   case .confirmDevice(let signedInData) = signInEvent.eventType {
                    let action = ConfirmDevice(signedInData: signedInData)
                    return .init(newState: .confirmingDevice,
                                 actions: [action])
                }
                
                if let signInEvent = event as? SignInEvent,
                   case .throwAuthError(let error) = signInEvent.eventType {
                    let action = ThrowSignInError(error: error)
                    return StateResolution(
                        newState: .error,
                        actions: [action])

                }
                return .from(oldState)
            }
        }

    }
}
