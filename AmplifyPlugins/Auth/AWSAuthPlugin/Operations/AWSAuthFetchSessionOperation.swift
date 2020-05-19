//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSAuthFetchSessionOperation: AmplifyOperation<AuthFetchSessionRequest,
    Void,
    AuthSession,
    AuthError>,
AuthFetchSessionOperation {

    let authenticationProvider: AuthenticationProviderBehavior
    let authorizationProvider: AuthorizationProviderBehavior

    init(_ request: AuthFetchSessionRequest,
         authenticationProvider: AuthenticationProviderBehavior,
         authorizationProvider: AuthorizationProviderBehavior,
         listener: EventListener?) {

        self.authenticationProvider = authenticationProvider
        self.authorizationProvider = authorizationProvider
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchSession,
                   request: request,
                   listener: listener)
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
            switch result {
            case .success(let session):
                self.dispatch(session)
            case .failure(let error):
                self.dispatch(error)
            }
        }
    }

    private func dispatch(_ result: AuthSession) {
        let asyncEvent = AsyncEvent<Void, AuthSession, AuthError>.completed(result)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        let asyncEvent = AsyncEvent<Void, AuthSession, AuthError>.failed(error)
        dispatch(event: asyncEvent)
    }
}
