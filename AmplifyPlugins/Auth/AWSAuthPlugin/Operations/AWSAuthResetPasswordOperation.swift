//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSAuthResetPasswordOperation: AmplifyOperation<AuthResetPasswordRequest,
    Void,
    AuthResetPasswordResult,
    AuthError>,
AuthResetPasswordOperation {

    let authenticationProvider: AuthenticationProviderBehavior

    init(_ request: AuthResetPasswordRequest,
         authenticationProvider: AuthenticationProviderBehavior,
         listener: EventListener?) {

        self.authenticationProvider = authenticationProvider
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.resetPassword,
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

        authenticationProvider.resetPassword(request: request) { [weak self] result in
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
            case .success(let resetPasswordResult):
                self.dispatch(resetPasswordResult)
            }
        }

    }

    private func dispatch(_ result: AuthResetPasswordResult) {
        let asyncEvent = AsyncEvent<Void, AuthResetPasswordResult, AuthError>.completed(result)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        let asyncEvent = AsyncEvent<Void, AuthResetPasswordResult, AuthError>.failed(error)
        dispatch(event: asyncEvent)
    }
}
