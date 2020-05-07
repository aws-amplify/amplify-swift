//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public class AWSAuthChangePasswordOperation: AmplifyOperation<AuthChangePasswordRequest,
    Void,
    Void,
    AmplifyAuthError>,
AuthChangePasswordOperation {

    let userService: AuthUserServiceBehavior

    init(_ request: AuthChangePasswordRequest,
         userService: AuthUserServiceBehavior,
         listener: EventListener?) {
        self.userService = userService
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.changePassword,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }
        userService.changePassword(request: request) { [weak self] result in
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
