//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

public extension AWSS3StoragePlugin {

    /// Resets the state of the plugin.
    ///
    /// Calls the reset methods on the storage service and authentication service to clean up resources. Setting the
    /// storage service, authentication service, and queue to nil to allow deallocation.
    ///
    /// - Tag: AWSS3StoragePlugin.reset
    func reset() async {
        if storageService != nil {
            storageService.reset()
            storageService = nil
        }
        if authService != nil {
            authService = nil
        }

        if queue != nil {
            queue = nil
        }
    }
}
