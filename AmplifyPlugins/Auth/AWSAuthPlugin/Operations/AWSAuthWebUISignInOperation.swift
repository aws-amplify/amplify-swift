//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSAuthWebUISignInOperation: AmplifyOperation<AuthWebUISignInRequest,
    Void,
    AuthSignInResult,
    AmplifyAuthError>,
AuthWebUISignInOperation {

    let authenticationProvider: AuthenticationProviderBehavior

    init(_ request: AuthWebUISignInRequest,
         authenticationProvider: AuthenticationProviderBehavior,
         listener: EventListener?) {

        self.authenticationProvider = authenticationProvider
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.webUISignIn,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        authenticationProvider.signInWithWebUI(request: request) {[weak self]  result in

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

    private func dispatch(_ result: AuthSignInResult) {
        let asyncEvent = AsyncEvent<Void, AuthSignInResult, AmplifyAuthError>.completed(result)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: AmplifyAuthError) {
        let asyncEvent = AsyncEvent<Void, AuthSignInResult, AmplifyAuthError>.failed(error)
        dispatch(event: asyncEvent)
    }
}
