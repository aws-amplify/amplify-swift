//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol AuthFederateToIdentityPoolOperation: AmplifyOperation<
    AuthFederateToIdentityPoolRequest,
    FederateToIdentityPoolResult,
    AuthError
> {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let federateToIdentityPoolAPI = "Auth.federatedToIdentityPool"
}

public class AWSAuthFederateToIdentityPoolOperation: AmplifyOperation<
    AuthFederateToIdentityPoolRequest,
    FederateToIdentityPoolResult,
    AuthError
>, AuthFederateToIdentityPoolOperation {

    init(_ request: AuthFederateToIdentityPoolRequest,
         authConfiguration: AuthConfiguration,
         authStateMachine: AuthStateMachine,
         resultListener: ResultListener?) {

        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.federateToIdentityPoolAPI,
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
