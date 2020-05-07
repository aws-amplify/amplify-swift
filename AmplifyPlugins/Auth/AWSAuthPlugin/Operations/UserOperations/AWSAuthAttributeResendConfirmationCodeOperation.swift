//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public class AWSAuthAttributeResendConfirmationCodeOperation: AmplifyOperation<
    AuthAttributeResendConfirmationCodeRequest,
    Void,
    AuthCodeDeliveryDetails,
    AmplifyAuthError>,
AuthAttributeResendConfirmationCodeOperation {

    let userService: AuthUserServiceBehavior

    init(_ request: AuthAttributeResendConfirmationCodeRequest,
         userService: AuthUserServiceBehavior,
         listener: EventListener?) {

        self.userService = userService
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.attributeResendConfirmationCode,
                   request: request,
                   listener: listener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }
        userService.resendAttributeConfirmationCode(request: request) { [weak self] result in
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

    private func dispatch(_ result: AuthCodeDeliveryDetails) {
        let asyncEvent = AsyncEvent<Void, AuthCodeDeliveryDetails, AmplifyAuthError>.completed(result)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: AmplifyAuthError) {
        let asyncEvent = AsyncEvent<Void, AuthCodeDeliveryDetails, AmplifyAuthError>.failed(error)
        dispatch(event: asyncEvent)
    }
}
