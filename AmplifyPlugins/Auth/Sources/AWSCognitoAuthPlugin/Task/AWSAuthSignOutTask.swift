//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class AWSAuthSignOutTask: AuthSignOutTask {

    private let request: AuthSignOutRequest
    private let authStateMachine: AuthStateMachine
    private var stateMachineToken: AuthStateMachineToken?
    private let taskHelper: AWSAuthTaskHelper
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signOutAPI
    }

    init(_ request: AuthSignOutRequest, authStateMachine: AuthStateMachine) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws {
        do {
            await taskHelper.didStateMachineConfigured()
            try await doSignOut()
            cancelToken()
        } catch {
            cancelToken()
            throw error
        }
    }

    private func doSignOut() async throws {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Error>) in
            stateMachineToken = authStateMachine.listen {[weak self] in
                guard let self = self else { return }
                guard case .configured(let authNState, _) = $0 else {
                    let error = AuthError.invalidState("Auth State not in a valid state", AuthPluginErrorConstants.invalidStateError,nil)
                    continuation.resume(throwing: error)
                    return
                }

                switch authNState {
                case .signedOut:
                    continuation.resume(returning: Void())
                case .error(let error):
                    continuation.resume(throwing: error.authError)
                case .signingIn:
                    self.authStateMachine.send(AuthenticationEvent.init(eventType: .cancelSignIn))
                default:
                    break
                }
            } onSubscribe: { [weak self] in
                guard let self = self else {
                    return
                }
                self.sendSignOutEvent()
            }
        }
    }
    
    private func sendSignOutEvent() {
        let signOutData = SignOutEventData(
            globalSignOut: request.options.globalSignOut,
            presentationAnchor: request.options.presentationAnchorForWebUI)
        let event = AuthenticationEvent(eventType: .signOutRequested(signOutData))
        authStateMachine.send(event)
    }
    
    private func cancelToken() {
        if let token = stateMachineToken {
            authStateMachine.cancel(listenerToken: token)
        }
    }
}
