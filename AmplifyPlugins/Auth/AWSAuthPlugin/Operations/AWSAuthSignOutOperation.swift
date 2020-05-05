//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSAuthSignOutOperation: AmplifyOperation<AuthSignOutRequest,
    Void,
    Void,
    AmplifyAuthError>,
AuthSignOutOperation {

    let authenticationProvider: AuthenticationProviderBehavior

    init(_ request: AuthSignOutRequest,
         authenticationProvider: AuthenticationProviderBehavior,
         listener: EventListener?) {

        self.authenticationProvider = authenticationProvider
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.signOut,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        authenticationProvider.signOut(request: request) { [weak self]  result in

            guard let self = self else { return }

            defer {
                self.finish()
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
