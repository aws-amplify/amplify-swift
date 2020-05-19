//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public class AWSAuthFetchUserAttributeOperation: AmplifyOperation<AuthFetchUserAttributesRequest,
    Void,
    [AuthUserAttribute],
    AuthError>,
AuthFetchUserAttributeOperation {

    let userService: AuthUserServiceBehavior

    init(_ request: AuthFetchUserAttributesRequest,
         userService: AuthUserServiceBehavior,
         listener: EventListener?) {

        self.userService = userService
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchUserAttributes,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        userService.fetchAttributes(request: request) { [weak self] result in
            guard let self = self else { return }
            defer {
                self.finish()
            }
            switch result {
            case .failure(let error):
                self.dispatch(error)
            case .success(let result):
                self.dispatch(result)
            }
        }
    }

    private func dispatch(_ result: [AuthUserAttribute]) {
        let asyncEvent = AsyncEvent<Void, [AuthUserAttribute], AuthError>.completed(result)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: AuthError) {
        let asyncEvent = AsyncEvent<Void, [AuthUserAttribute], AuthError>.failed(error)
        dispatch(event: asyncEvent)
    }
}
