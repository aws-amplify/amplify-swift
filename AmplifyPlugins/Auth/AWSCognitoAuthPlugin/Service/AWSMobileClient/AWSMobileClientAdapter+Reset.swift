//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSMobileClientAdapter: Resettable {

    /// Resets the underlying AWSMobileClient
    func reset(onComplete: @escaping BasicClosure) {
        awsMobileClient.reset(onComplete: onComplete)
    }
}
