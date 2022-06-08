//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias AmplifyFetchSessionOperation = AmplifyOperation<AuthFetchSessionRequest, AuthSession, AuthError>

public class AWSAuthFetchSessionOperation: AmplifyFetchSessionOperation, AuthFetchSessionOperation {

    let authStateMachine: AuthStateMachine
    let credentialStoreStateMachine: CredentialStoreStateMachine
    private let fetchSessionHelper: FetchAuthSessionOperationHelper

    init(_ request: AuthFetchSessionRequest,
         authStateMachine: AuthStateMachine,
         credentialStoreStateMachine: CredentialStoreStateMachine,
         resultListener: ResultListener?) {

        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        fetchSessionHelper = FetchAuthSessionOperationHelper(
            authStateMachine: authStateMachine,
            credentialStoreStateMachine: credentialStoreStateMachine)
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchSessionAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }
        
        fetchSessionHelper.fetchSession { [weak self] result in
            switch result {
            case .success(let session):
                self?.dispatch(session)
            case .failure(let error):
                self?.dispatch(error)
            }
        }
    }

    private func dispatch(_ result: AuthSession) {
        finish()
        let asyncEvent = AWSAuthFetchSessionOperation.OperationResult.success(result)
        dispatch(result: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        finish()
        let asyncEvent = AWSAuthFetchSessionOperation.OperationResult.failure(error)
        dispatch(result: asyncEvent)
    }

}
