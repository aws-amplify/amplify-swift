//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSAuthConfirmResetPasswordOperation: AmplifyOperation<AuthConfirmResetPasswordRequest,
    Void,
    Void,
    AmplifyAuthError>,
AuthConfirmResetPasswordOperation {

    let authenticationProvider: AuthenticationProviderBehavior

    init(_ request: AuthConfirmResetPasswordRequest,
         authenticationProvider: AuthenticationProviderBehavior,
         listener: EventListener?) {

        self.authenticationProvider = authenticationProvider
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.confirmResetPassword,
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
        authenticationProvider.confirmResetPassword(request: request) { [weak self] result in
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
            case .success:
                self.dispatchSuccess()
            }
        }
    }

    private func dispatchSuccess() {
        let asyncEvent = AsyncEvent<Void, Void, AmplifyAuthError>.completed(())
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: AmplifyAuthError) {
        let asyncEvent = AsyncEvent<Void, Void, AmplifyAuthError>.failed(error)
        dispatch(event: asyncEvent)
    }
}
