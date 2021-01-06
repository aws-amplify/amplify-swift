//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public class AWSAuthFetchUserAttributeOperation: AmplifyOperation<
    AuthFetchUserAttributesRequest,
    [AuthUserAttribute],
    AuthError
>, AuthFetchUserAttributeOperation {

    let userService: AuthUserServiceBehavior

    init(_ request: AuthFetchUserAttributesRequest,
         userService: AuthUserServiceBehavior,
         resultListener: ResultListener?) {

        self.userService = userService
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchUserAttributesAPI,
                   request: request,
                   resultListener: resultListener)
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
            if self.isCancelled {
                return
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
        let result = OperationResult.success(result)
        dispatch(result: result)
    }

    private func dispatch(_ error: AuthError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }
}
