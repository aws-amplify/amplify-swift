//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSCognitoAuthPlugin {

    public func reset(onComplete: @escaping BasicClosure) {

        if let resettable = authorizationProvider as? Resettable {
            resettable.reset { [weak self] in
                self?.completeReset(onComplete: onComplete)
            }
        } else {
            completeReset(onComplete: onComplete)
        }
    }

    func completeReset(onComplete: @escaping BasicClosure) {
        authorizationProvider = nil
        authenticationProvider = nil
        userService = nil
        deviceService = nil
        hubEventHandler = nil
        onComplete()
    }
}
