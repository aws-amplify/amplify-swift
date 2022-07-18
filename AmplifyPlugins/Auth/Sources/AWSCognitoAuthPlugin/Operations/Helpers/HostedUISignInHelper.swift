//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class HostedUISignInHelper {

    let request: AuthWebUISignInRequest

    let authStateMachine: AuthStateMachine

    let configuration: AuthConfiguration

    var token: AuthStateMachine.StateChangeListenerToken?

    var completion: ((Result<AuthSignInResult, AuthError>) -> Void)?

    init(request: AuthWebUISignInRequest,
         authstateMachine: AuthStateMachine,
         configuration: AuthConfiguration) {
        self.request = request
        self.authStateMachine = authstateMachine
        self.configuration = configuration
        token = nil
        completion = nil
    }

    func initiateSignIn(completion: @escaping (Result<AuthSignInResult, AuthError>) -> Void) {
        self.completion = completion

        authStateMachine.getCurrentState { state in
            guard case .configured(let authenticationState, _) = state else {
                return
            }

            switch authenticationState {
            case .signedIn:
                let error = AuthError.invalidState(
                    "There is already a user in signedIn state. SignOut the user first before calling signIn",
                    AuthPluginErrorConstants.invalidStateError, nil)
                completion(.failure(error))
                return
            default:
                self.prepareForSignIn()
            }
        }
    }

    private func prepareForSignIn() {

        token = authStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            guard case .configured(let authNState, _) = $0 else { return }

            switch authNState {
            case .signedOut:
                self.cancelToken(self.token)
                self.doSignIn()

            case .signingUp:
                self.sendCancelSignUpEvent()

            case .signingIn:
                self.sendCancelSignInEvent()

            default:
                break
            }
        } onSubscribe: { }
    }

    private func doSignIn() {

        let oauthConfiguration: OAuthConfigurationData
        switch configuration {
        case .userPools(let userPoolConfigurationData),
                .userPoolsAndIdentityPools(let userPoolConfigurationData, _):
            guard let internalConfig = userPoolConfigurationData.hostedUIConfig?.oauth else {
                fatalError("TODO: Throw error")
            }
            oauthConfiguration = internalConfig

        default:
            fatalError("TODO: Throw error")
        }

        token = authStateMachine.listen { [weak self] state in
            guard let self = self else {
                return
            }

            guard case .configured(let authNState,
                                   let authZState) = state else { return }

            switch authNState {
            case .signedIn:
                if case .sessionEstablished = authZState {
                    self.cancelToken(self.token)
                    self.completion?(.success(AuthSignInResult(nextStep: .done)))
                }

            case .error(let error):
                self.cancelToken(self.token)
                let error = AuthError.unknown("Sign in reached an error state", error)
                self.completion?(.failure(error))
            case .signingIn(let signInState):
                guard let result = UserPoolSignInHelper.checkNextStep(signInState) else {
                    return
                }
                self.cancelToken(self.token)
                self.completion?(result)
            default:
                break
            }
        } onSubscribe: {
            self.sendSignInEvent(oauthConfiguration: oauthConfiguration)
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

    private func sendCancelSignUpEvent() {
        let event = AuthenticationEvent(eventType: .cancelSignUp)
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
