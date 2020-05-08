//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public class AWSAuthConfirmUserAttributeOperation: AmplifyOperation<AuthConfirmUserAttributeRequest,
    Void,
    Void,
    AmplifyAuthError>,
AuthConfirmUserAttributeOperation {

    let userService: AuthUserServiceBehavior

    init(_ request: AuthConfirmUserAttributeRequest,
         userService: AuthUserServiceBehavior,
         listener: EventListener?) {

        self.userService = userService
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.confirmUserAttributes,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        userService.confirmAttribute(request: request) { [weak self] result in
            guard let self = self else { return }
            defer {
                self.finish()
            }
            switch result {
            case .failure(let error):
                self.dispatch(error)
            case .success(let confirmAttributeResult):
                self.dispatch(confirmAttributeResult)
            }
        }

    }

    private func dispatch(_ result: Void) {
        let asyncEvent = AsyncEvent<Void, Void, AmplifyAuthError>.completed(result)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: AmplifyAuthError) {
        let asyncEvent = AsyncEvent<Void, Void, AmplifyAuthError>.failed(error)
        dispatch(event: asyncEvent)
    }
}
