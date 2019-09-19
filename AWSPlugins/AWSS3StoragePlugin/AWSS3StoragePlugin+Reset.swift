//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import AWSMobileClient
import Amplify

extension AWSS3StoragePlugin {

    /// Resets the state of the plugin.
    ///
    /// Calls the reset methods on the storage service and authentication service to clean up resources. Setting the
    /// storage service, authenication service, and queue to nil to allow deallocation, then calls onComplete closure
    /// to signal the reset has completed.
    public func reset(onComplete: @escaping (() -> Void)) {
        if storageService != nil {
            storageService.reset()
            storageService = nil
        }
        if authService != nil {
            authService.reset()
            authService = nil
        }

        if queue != nil {
            queue = nil
        }

        onComplete()
    }
}
