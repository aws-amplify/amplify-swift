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
    static let clearFederationToIdentityPoolAPI = "Auth.federatedToIdentityPoolCleared"
}

public class AWSAuthClearFederationToIdentityPoolOperation: AmplifyOperation<
    AuthClearFederationToIdentityPoolRequest,
    Void,
    AuthError
>, AuthClearFederationToIdentityPoolOperation {

    init(_ request: AuthClearFederationToIdentityPoolRequest,
         authConfiguration: AuthConfiguration,
         authStateMachine: AuthStateMachine,
         resultListener: ResultListener?) {

        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.clearFederationToIdentityPoolAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

    }
}
