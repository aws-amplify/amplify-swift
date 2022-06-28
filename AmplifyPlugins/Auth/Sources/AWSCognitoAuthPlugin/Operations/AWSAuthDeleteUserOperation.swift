//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

public class AWSAuthDeleteUserOperation: AmplifyOperation<
    AuthDeleteUserRequest,
    Void,
    AuthError
>, AuthDeleteUserOperation {

    private let authStateMachine: AuthStateMachine
    private var stateListenerToken: AuthStateMachineToken?
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper

    init(_ request: AuthDeleteUserRequest,
         authStateMachine: AuthStateMachine,
         resultListener: ResultListener?) {
        self.authStateMachine = authStateMachine
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.confirmUserAttributesAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }
        
        fetchAuthSessionHelper.fetch(authStateMachine) { [weak self] result in
            switch result {
            case .success(let session):
                guard let cognitoTokenProvider = session as? AuthCognitoTokensProvider,
                      let tokens = try? cognitoTokenProvider.getCognitoTokens().get() else {
                    self?.dispatch(AuthError.unknown("Unable to fetch auth session", nil))
                    return
                }
                Task.init { [weak self] in
                    await self?.deleteUser(with: tokens.accessToken)
                }
            case .failure(let error):
                self?.dispatch(error)
            }
        }
    }
    
    private func deleteUser(with token: String) async {
        
        stateListenerToken = authStateMachine.listen({ [weak self] state in
            guard let self = self else { return }
            // check if deletion is successful
            
            guard case .configured(let authNState, _) = state else {
                self.dispatch(AuthError.invalidState(
                    "Auth state should be in configured state and authentication state should be in deleting user state",
                    AuthPluginErrorConstants.invalidStateError, nil))
                return
            }
            
            guard case .deletingUser(_, let deleteUserState) = authNState else {
                return
            }
            
            switch deleteUserState {
            case .userDeleted:
                self.dispatchSuccess()
                
                if let stateListenerToken = self.stateListenerToken {
                    self.authStateMachine.cancel(listenerToken: stateListenerToken)
                }
            case .error(let error):
                self.dispatch(error)
                
                if let stateListenerToken = self.stateListenerToken {
                    self.authStateMachine.cancel(listenerToken: stateListenerToken)
                }
            default:
                break
            }

        }, onSubscribe: { [weak self] in
            let deleteUserEvent = DeleteUserEvent(eventType: .deleteUser(token))
            self?.authStateMachine.send(deleteUserEvent)
        })
        
    }

    private func dispatchSuccess() {
        let result = OperationResult.success(())
        dispatch(result: result)
        finish()
    }

    private func dispatch(_ error: AuthError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
        finish()
    }
}
