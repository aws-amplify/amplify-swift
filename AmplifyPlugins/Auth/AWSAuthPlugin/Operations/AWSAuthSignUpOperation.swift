//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSMobileClient

public class AWSAuthSignUpOperation: AmplifyOperation<AuthSignUpRequest,
    Void,
    AuthSignUpResult,
    AmplifyAuthError>,
AuthSignUpOperation {

    let authenticationProvider: AuthenticationProviderBehavior

    init(_ request: AuthSignUpRequest,
         authenticationProvider: AuthenticationProviderBehavior,
         listener: EventListener?) {

        self.authenticationProvider = authenticationProvider
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.signUp,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        if isCancelled {
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
        let asyncEvent = AsyncEvent<Void, AuthSignUpResult, AmplifyAuthError>.completed(result)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: AmplifyAuthError) {
        let asyncEvent = AsyncEvent<Void, AuthSignUpResult, AmplifyAuthError>.failed(error)
        dispatch(event: asyncEvent)
    }
}
