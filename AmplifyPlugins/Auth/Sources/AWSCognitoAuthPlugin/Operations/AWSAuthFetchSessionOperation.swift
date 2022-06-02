//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias AmplifyFetchSessionOperation = AmplifyOperation<
    AuthFetchSessionRequest,
    AuthSession,
    AuthError>

public class AWSAuthFetchSessionOperation: AmplifyFetchSessionOperation,
                                           AuthFetchSessionOperation {

    let authStateMachine: AuthStateMachine
    private let fetchSessionHelper: FetchAuthSessionOperationHelper

    init(_ request: AuthFetchSessionRequest,
         authStateMachine: AuthStateMachine,
         resultListener: ResultListener?) {
        
        self.authStateMachine = authStateMachine
        fetchSessionHelper = FetchAuthSessionOperationHelper()
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

        fetchSessionHelper.fetch(authStateMachine) { [weak self] result in
            self?.dispatch(result: result)
            self?.finish()
        }
    }

}
