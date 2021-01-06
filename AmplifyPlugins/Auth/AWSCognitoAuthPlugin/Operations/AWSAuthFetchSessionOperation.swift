//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSAuthFetchSessionOperation: AmplifyOperation<
    AuthFetchSessionRequest,
    AuthSession,
    AuthError
>, AuthFetchSessionOperation {

    let authenticationProvider: AuthenticationProviderBehavior
    let authorizationProvider: AuthorizationProviderBehavior

    init(_ request: AuthFetchSessionRequest,
         authenticationProvider: AuthenticationProviderBehavior,
         authorizationProvider: AuthorizationProviderBehavior,
         resultListener: ResultListener?) {

        self.authenticationProvider = authenticationProvider
        self.authorizationProvider = authorizationProvider
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

        authorizationProvider.fetchSession(request: request) { [weak self]  result in

            guard let self = self else { return }
            defer {
                self.finish()
            }

            if self.isCancelled {
                return
            }

            switch result {
            case .success(let session):
                self.dispatch(session)
            case .failure(let error):
                self.dispatch(error)
            }
        }
    }

    private func dispatch(_ result: AuthSession) {
        let result = OperationResult.success(result)
        dispatch(result: result)
    }

    private func dispatch(_ error: AuthError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }
}
