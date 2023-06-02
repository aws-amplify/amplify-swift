//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct HostedUISignInHelper: DefaultLogger {

    let request: AuthWebUISignInRequest

    let authStateMachine: AuthStateMachine

    let configuration: AuthConfiguration

    init(request: AuthWebUISignInRequest,
         authstateMachine: AuthStateMachine,
         configuration: AuthConfiguration) {
        self.request = request
        self.authStateMachine = authstateMachine
        self.configuration = configuration
    }

    func initiateSignIn() async throws -> AuthSignInResult {
        try await isValidState()
        do {
            log.verbose("Start signIn flow")
            let result = try await doSignIn()
            log.verbose("Received result")
            return result
        } catch {
            await waitForSignInCancel()
            throw error
        }
    }

    func isValidState() async throws {
        let stateSequences = await authStateMachine.listen()
        log.verbose("Wait for a valid state")
        for await state in stateSequences {
            guard case .configured(let authenticationState, _) = state else {
                continue
            }
            switch authenticationState {
            case .signingIn:
                await sendCancelSignInEvent()
            case .signedIn:
                throw AuthError.invalidState(
                    "There is already a user in signedIn state. SignOut the user first before calling signIn",
                    AuthPluginErrorConstants.invalidStateError, nil)
            case .signedOut:
                return
            default: continue
            }
        }
    }


    private func doSignIn() async throws -> AuthSignInResult {

        let oauthConfiguration: OAuthConfigurationData
        switch configuration {
        case .userPools(let userPoolConfigurationData),
                .userPoolsAndIdentityPools(let userPoolConfigurationData, _):
            guard let internalConfig = userPoolConfigurationData.hostedUIConfig?.oauth else {
                let message = AuthPluginErrorConstants.configurationError
                let authError = AuthenticationError.configuration(message: message)
                throw authError
            }
            oauthConfiguration = internalConfig

        default:
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthenticationError.configuration(message: message)
            throw authError
        }
        let stateSequences = await authStateMachine.listen()
        await sendSignInEvent(oauthConfiguration: oauthConfiguration)
        log.verbose("Wait for signIn to complete")
        for await state in stateSequences {
            guard case .configured(let authNState,
                                   let authZState) = state else { continue }

            switch authNState {
            case .signedIn:
                if case .sessionEstablished = authZState {
                    return AuthSignInResult(nextStep: .done)
                } else if case .error(let error) = authZState {
                    log.verbose("Authorization reached an error state \(error)")
                    throw error.authError
                }

            case .error(let error):
                throw error.authError

            case .signingIn(let signInState):
                guard let result = try UserPoolSignInHelper.checkNextStep(signInState) else {
                    continue
                }
                return result
            default:
                continue
            }
        }
        throw AuthError.unknown("Could not signin to webUI")

    }

    private func sendSignInEvent(oauthConfiguration: OAuthConfigurationData) async {

        let pluginOptions = request.options.pluginOptions as? AWSAuthWebUISignInOptions
        let privateSession = pluginOptions?.preferPrivateSession ?? false
        let idpIdentifier = pluginOptions?.idpIdentifier

        let providerInfo = HostedUIProviderInfo(authProvider: request.authProvider,
                                                idpIdentifier: idpIdentifier)
        let scopeFromConfig = oauthConfiguration.scopes
#if os(iOS) || os(macOS)
        let hostedUIOptions = HostedUIOptions(scopes: request.options.scopes ?? scopeFromConfig,
                                              providerInfo: providerInfo,
                                              presentationAnchor: request.presentationAnchor,
                                              preferPrivateSession: privateSession)
#else
        let hostedUIOptions = HostedUIOptions(scopes: request.options.scopes ?? scopeFromConfig,
                                              providerInfo: providerInfo,
                                              presentationAnchor: nil,
                                              preferPrivateSession: privateSession)

#endif
        let signInData = SignInEventData(username: nil,
                                         password: nil,
                                         signInMethod: .hostedUI(hostedUIOptions))
        let event = AuthenticationEvent.init(eventType: .signInRequested(signInData))
        await authStateMachine.send(event)
    }

    private func sendCancelSignInEvent() async {
        let event = AuthenticationEvent(eventType: .cancelSignIn)
        await authStateMachine.send(event)
    }

    private func waitForSignInCancel() async {
        log.verbose("Sending cancel signIn")
        await sendCancelSignInEvent()
        log.verbose("Wait for signIn to cancel")
        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard case .configured(let authenticationState, _) = state else {
                continue
            }

            switch authenticationState {
            case .signedOut:
                return
            case .signingOut(let signingOutState):
                if case .error = signingOutState {
                    return
                }
            default: continue
            }
        }
    }
}
