//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct HostedUISignInHelper {

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
        return try await doSignIn()
    }

    func isValidState() async throws {
        let stateSequences = await authStateMachine.listen()
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
        for await state in stateSequences {
            guard case .configured(let authNState,
                                   let authZState) = state else { continue }

            switch authNState {
            case .signedIn:
                if case .sessionEstablished = authZState {
                   return AuthSignInResult(nextStep: .done)
                }

            case .error(let error):
                await waitforSignInCancel()
                throw error.authError

            case .signingIn(let signInState):
                do {
                    guard let result = try UserPoolSignInHelper.checkNextStep(signInState) else {
                        continue
                    }
                    return result
                } catch {
                    await waitforSignInCancel()
                    throw error
                }
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
        let hostedUIOptions = HostedUIOptions(scopes: request.options.scopes ?? scopeFromConfig,
                                              providerInfo: providerInfo,
                                              presentationAnchor: request.presentationAnchor,
                                              preferPrivateSession: privateSession)
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

    private func waitforSignInCancel() async {
        await sendCancelSignInEvent()
        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard case .configured(let authenticationState, _) = state else {
                continue
            }

            switch authenticationState {
            case .signedOut:
                return
            default: continue
            }
        }
    }
}
