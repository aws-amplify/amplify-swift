//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthWebUISignInTask: AuthWebUISignInTask {

    private let helper: HostedUISignInHelper
    private let request: AuthWebUISignInRequest
    private let authStateMachine: AuthStateMachine
    private var stateMachineToken: AuthStateMachineToken?
    let eventName: HubPayloadEventName
    
    init(_ request: AuthWebUISignInRequest,
         authConfiguration: AuthConfiguration,
         authStateMachine: AuthStateMachine,
         eventName: String
    ) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.helper = HostedUISignInHelper(request: request, authstateMachine: authStateMachine, configuration: authConfiguration)
        self.eventName = eventName
    }

    func execute() async throws -> AuthSignInResult {

        do {
            await didConfigure()
            let result = try await helper.initiateSignIn()
            return result
        } catch let autherror as AuthErrorConvertible {
            throw autherror.authError
        } catch let autherror as AuthError {
            throw autherror
        } catch let error {
            let error = AuthError.unknown("Not able to signIn to the webUI", error)
            throw error
        }
    }
    
    private func didConfigure() async {
        await withCheckedContinuation { [weak self] (continuation: CheckedContinuation<Void, Never>) in
            stateMachineToken = authStateMachine.listen({ [weak self] state in
                guard let self = self, case .configured = state else { return }
                self.authStateMachine.cancel(listenerToken: self.stateMachineToken!)
                continuation.resume()
            }, onSubscribe: {})
        }
    }
}
