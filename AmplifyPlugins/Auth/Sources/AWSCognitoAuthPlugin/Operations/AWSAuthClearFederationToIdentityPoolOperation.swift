//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol AuthClearFederationToIdentityPoolOperation: AmplifyOperation<
    AuthClearFederationToIdentityPoolRequest,
    Void,
    AuthError
> {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let clearedFederationToIdentityPoolAPI = "Auth.federationToIdentityPoolCleared"
}

public class AWSAuthClearFederationToIdentityPoolOperation: AmplifyOperation<
    AuthClearFederationToIdentityPoolRequest,
    Void,
    AuthError
>, AuthClearFederationToIdentityPoolOperation {

    let authStateMachine: AuthStateMachine
    let clearFederationHelper: ClearFederationOperationHelper

    init(_ request: AuthClearFederationToIdentityPoolRequest,
         authStateMachine: AuthStateMachine,
         resultListener: ResultListener?) {

        self.authStateMachine = authStateMachine
        clearFederationHelper = ClearFederationOperationHelper()
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.clearedFederationToIdentityPoolAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }
        clearFederationHelper.clearFederation(
            authStateMachine) { [weak self] result in
                self?.dispatch(result: result)
                self?.finish()
            }
    }

}
