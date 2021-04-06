//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

public class AWSAuthSignUpOperation: AmplifyOperation<
    AuthSignUpRequest,
    AuthSignUpResult,
    AuthError
>, AuthSignUpOperation {

    let authenticationProvider: AuthenticationProviderBehavior

    init(_ request: AuthSignUpRequest,
         authenticationProvider: AuthenticationProviderBehavior,
         resultListener: ResultListener?) {

        self.authenticationProvider = authenticationProvider
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.signUpAPI,
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

        authenticationProvider.signUp(request: request) { [weak self] result in
            guard let self = self else { return }

            defer {
                self.finish()
            }

            if self.isCancelled {
                return
            }

            switch result {
            case .success(let signUpResult):
                self.dispatch(signUpResult)
            case .failure(let signUpError):
                self.dispatch(signUpError)
            }
        }
    }

    private func dispatch(_ result: AuthSignUpResult) {
        let result = OperationResult.success(result)
        dispatch(result: result)
    }

    private func dispatch(_ error: AuthError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }
}
