//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

extension AWSS3StoragePlugin {

    /// Resets the state of the plugin.
    ///
    /// Calls the reset methods on the storage service and authentication service to clean up resources. Setting the
    /// storage service, authentication service, and queue to nil to allow deallocation.
    ///
    /// - Tag: AWSS3StoragePlugin.reset
    public func reset() async {
        if defaultBucket != nil {
            defaultBucket = nil
        }

        for storageService in storageServicesByBucket.values {
            storageService.reset()
        }
        storageServicesByBucket.removeAll()

        if additionalBucketsByName != nil {
            additionalBucketsByName = nil
        }

        if authService != nil {
            authService = nil
        }

        if queue != nil {
            queue = nil
        }
    }
}
