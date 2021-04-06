//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

public class AWSAuthResendSignUpCodeOperation: AmplifyOperation<
    AuthResendSignUpCodeRequest,
    AuthCodeDeliveryDetails,
    AuthError
>, AuthResendSignUpCodeOperation {

    let authenticationProvider: AuthenticationProviderBehavior

    init(_ request: AuthResendSignUpCodeRequest,
         authenticationProvider: AuthenticationProviderBehavior,
         resultListener: ResultListener?) {

        self.authenticationProvider = authenticationProvider
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.resendSignUpCodeAPI,
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

        authenticationProvider.resendSignUpCode(request: request) {[weak self]  result in

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

    private func dispatch(_ result: AuthCodeDeliveryDetails) {
        let result = OperationResult.success(result)
        dispatch(result: result)
    }

    private func dispatch(_ error: AuthError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }
}
