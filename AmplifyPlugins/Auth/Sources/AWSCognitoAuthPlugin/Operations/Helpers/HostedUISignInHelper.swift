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

    func initiateSignIn() async throws -> AuthSignInResult  {
        try await isValidState()
        await prepareForSignIn()
        return try await doSignIn()
    }

    func isValidState() async throws {
        try await withCheckedThrowingContinuation { (continuation: (CheckedContinuation<Void, Error>)) in
            authStateMachine.getCurrentState { state in
                guard case .configured(let authenticationState, _) = state else {
                    return
                }

                switch authenticationState {
                case .signedIn:
                    let error = AuthError.invalidState(
                        "There is already a user in signedIn state. SignOut the user first before calling signIn",
                        AuthPluginErrorConstants.invalidStateError, nil)
                    continuation.resume(with: .failure(error))

                default:
                    continuation.resume(with: .success(Void()))
                }
            }
        }
    }

    private func prepareForSignIn() async {
        var token: AuthStateMachine.StateChangeListenerToken?
        await withCheckedContinuation { (continuation: (CheckedContinuation<Void, Never>)) in
            token = authStateMachine.listen { 

                guard case .configured(let authNState, _) = $0 else { return }

                switch authNState {
                case .signedOut:
                    cancelToken(token)
                    continuation.resume()

                case .signingIn:
                   sendCancelSignInEvent()

                default:
                    break
                }
            } onSubscribe: { }
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
        var token: AuthStateMachine.StateChangeListenerToken?
        return try await withCheckedThrowingContinuation { (continuation: (CheckedContinuation<AuthSignInResult, Error>)) in
            token = authStateMachine.listen {  state in

                guard case .configured(let authNState,
                                       let authZState) = state else { return }

                switch authNState {
                case .signedIn:
                    if case .sessionEstablished = authZState {
                       cancelToken(token)
                        continuation.resume(with: .success(AuthSignInResult(nextStep: .done)))
                    }

                case .error(let error):
                    cancelToken(token)
                    let error = AuthError.unknown("Sign in reached an error state", error)
                    continuation.resume(with: .failure(error))

                case .signingIn(let signInState):
                    guard let result = UserPoolSignInHelper.checkNextStep(signInState) else {
                        return
                    }
                   cancelToken(token)
                    continuation.resume(with: result)
                default:
                    break
                }
            } onSubscribe: {
                sendSignInEvent(oauthConfiguration: oauthConfiguration)
            }
        }

    }

    private func sendSignInEvent(oauthConfiguration: OAuthConfigurationData) {

        let pluginOptions = request.options.pluginOptions as? AWSAuthWebUISignInOptions
        let privateSession = pluginOptions?.preferPrivateSession ?? false
        let idpIdentifier = pluginOptions?.idpIdentifier
        let federationProviderName = pluginOptions?.federationProviderName

        let providerInfo = HostedUIProviderInfo(authProvider: request.authProvider,
                                                idpIdentifier: idpIdentifier,
                                                federationProviderName: federationProviderName)
        let scopeFromConfig = oauthConfiguration.scopes
        let hostedUIOptions = HostedUIOptions(scopes: request.options.scopes ?? scopeFromConfig,
                                              providerInfo: providerInfo,
                                              presentationAnchor: request.presentationAnchor,
                                              preferPrivateSession: privateSession)
        let signInData = SignInEventData(username: nil,
                                         password: nil,
                                         signInMethod: .hostedUI(hostedUIOptions))
        let event = AuthenticationEvent.init(eventType: .signInRequested(signInData))
        authStateMachine.send(event)
    }

    private func sendCancelSignInEvent() {
        let event = AuthenticationEvent(eventType: .cancelSignIn)
        authStateMachine.send(event)
    }

    private func cancelToken(_ token: AuthStateMachineToken?) {
        if let token = token {
            authStateMachine.cancel(listenerToken: token)
        }
    }

}
