//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthorizationProviderAdapter: Resettable {

    func reset(onComplete: @escaping BasicClosure) {
        // There is no method in awsmobileClient to remove all listeners in one go. So remove the listener here first
        // and then invoke reset on the awsmobileClient.
        awsMobileClient.removeUserStateListener(self)

        if let resettable = awsMobileClient as? Resettable {
            Amplify.log.verbose("Resetting awsMobileClient")
            resettable.reset {
                Amplify.log.verbose("Resetting awsMobileClient: finished")
                onComplete()
            }
        } else {
            onComplete()
        }
    }
}
