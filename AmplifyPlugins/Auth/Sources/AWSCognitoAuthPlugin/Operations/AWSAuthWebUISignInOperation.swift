//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSAuthWebUISignInOperation: AmplifyOperation<
    AuthWebUISignInRequest,
    AuthSignInResult,
    AuthError
>, AuthWebUISignInOperation {

    let authStateMachine: AuthStateMachine

    let configuration: AuthConfiguration

    init(_ request: AuthWebUISignInRequest,
         authConfiguration: AuthConfiguration,
         authStateMachine: AuthStateMachine,
         resultListener: ResultListener?) {

        self.authStateMachine = authStateMachine
        self.configuration = authConfiguration
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.webUISignInAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        authStateMachine.getCurrentState { [weak self] in
            guard case .configured(let authenticationState, _) = $0 else {
                return
            }

            switch authenticationState {
            case .signedIn:
                self?.dispatch(AuthError.invalidState(
                    "There is already a user in signedIn state. SignOut the user first before calling signIn",
                    AuthPluginErrorConstants.invalidStateError, nil))
                self?.finish()
            default:
                self?.doSignIn()
            }
        }
    }

    func doSignIn() {
        if isCancelled {
            finish()
            return
        }

        let oauthConfiguration: OAuthConfigurationData
        switch configuration {
        case .userPools(let userPoolConfigurationData),
                .userPoolsAndIdentityPools(let userPoolConfigurationData, _):

            guard let internalConfig = userPoolConfigurationData.hostedUIConfig?.oauth else {

                finish()
                return
            }
            oauthConfiguration = internalConfig

        default:
            fatalError("TODO: Throw error")
        }

        var token: AuthStateMachine.StateChangeListenerToken?
        token = authStateMachine.listen { [weak self] in
            guard let self = self else {
                return
            }
            guard case .configured(let authNState,
                                   let authZState) = $0 else { return }

            switch authNState {
            case .signedOut:
                self.sendSignInEvent(oauthConfiguration: oauthConfiguration)

            case .signingUp:
                self.sendCancelSignUpEvent()

            case .signedIn:
                if case .sessionEstablished = authZState {
                    self.dispatch(AuthSignInResult(nextStep: .done))
                    self.cancelToken(token)
                    self.finish()
                }

            case .error(let error):
                self.dispatch(AuthError.unknown("Sign in reached an error state", error))
                self.cancelToken(token)
                self.finish()

            case .signingIn(let signInState):
                guard let result = UserPoolSignInHelper.checkNextStep(signInState) else {
                    return
                }
                self.dispatch(result: result)
                self.cancelToken(token)
                self.finish()
            default:
                break
            }
        } onSubscribe: { }
    }

    private func sendSignInEvent(oauthConfiguration: OAuthConfigurationData) {

        let scopeFromConfig = oauthConfiguration.scopes
        let hostedUIOptions = HostedUIOptions(scopes: request.options.scopes ?? scopeFromConfig,
                                              presentationAnchor: request.presentationAnchor)
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

    private func dispatch(_ result: AuthSignInResult) {
        let asyncEvent = AWSAuthSignInOperation.OperationResult.success(result)
        dispatch(result: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        let asyncEvent = AWSAuthSignInOperation.OperationResult.failure(error)
        dispatch(result: asyncEvent)
    }

    private func cancelToken(_ token: AuthStateMachineToken?) {
        if let token = token {
            authStateMachine.cancel(listenerToken: token)
        }
    }
}
