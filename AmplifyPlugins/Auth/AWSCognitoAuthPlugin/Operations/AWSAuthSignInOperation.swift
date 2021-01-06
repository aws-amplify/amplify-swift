//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSAuthSignInOperation: AmplifyOperation<
    AuthSignInRequest,
    AuthSignInResult,
    AuthError
>, AuthSignInOperation {

    let authenticationProvider: AuthenticationProviderBehavior

    init(_ request: AuthSignInRequest,
         authenticationProvider: AuthenticationProviderBehavior,
         resultListener: ResultListener?) {

        self.authenticationProvider = authenticationProvider
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.signInAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        if let validationError = request.hasError() {
            dispatch(validationError)
            finish()
            return
        }

        authenticationProvider.signIn(request: request) {[weak self]  result in
            guard let self = self else { return }

            defer {
                self.finish()
            }

            if self.isCancelled {
                return
            }

            switch result {
            case .failure(let error):
                self.dispatch(error)
            case .success(let signInResult):
                self.dispatch(signInResult)
            }
        }
    }

    private func dispatch(_ result: AuthSignInResult) {
        let asyncEvent = AWSAuthSignInOperation.OperationResult.success(result)
        dispatch(result: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        let asyncEvent = AWSAuthSignInOperation.OperationResult.failure(error)
        dispatch(result: asyncEvent)
    }
}
