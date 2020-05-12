//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

public class AWSAuthResendSignUpCodeOperation: AmplifyOperation<AuthResendSignUpCodeRequest,
    Void,
    AuthCodeDeliveryDetails,
    AuthError>,
AuthResendSignUpCodeOperation {

    let authenticationProvider: AuthenticationProviderBehavior

    init(_ request: AuthResendSignUpCodeRequest,
         authenticationProvider: AuthenticationProviderBehavior,
         listener: EventListener?) {

        self.authenticationProvider = authenticationProvider
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.resendSignUpCode,
                   request: request,
                   listener: listener)
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
            switch result {
            case .failure(let error):
                self.dispatch(error)
            case .success(let signInResult):
                self.dispatch(signInResult)
            }
        }
    }

    private func dispatch(_ result: AuthCodeDeliveryDetails) {
        let asyncEvent = AsyncEvent<Void, AuthCodeDeliveryDetails, AuthError>.completed(result)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        let asyncEvent = AsyncEvent<Void, AuthCodeDeliveryDetails, AuthError>.failed(error)
        dispatch(event: asyncEvent)
    }
}
