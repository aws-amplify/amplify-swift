//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

// The AWSS3StoragePlugin which conforms to the Amplify plugin protocols and implements the Storage Plugin APIs for S3.
final public class AWSS3StoragePlugin: StorageCategoryPlugin {

    /// An instance of the S3 storage service.
    var storageService: AWSS3StorageServiceBehaviour!

    /// An instance of the authentication service.
    var authService: AWSAuthServiceBehavior!

    /// A queue that regulates the execution of operations.
    var queue: OperationQueue!

    /// The default access level used for API calls.
    var defaultAccessLevel: StorageAccessLevel!

    /// The unique key of the plugin within the storage category.
    public var key: PluginKey {
        return PluginConstants.awsS3StoragePluginKey
    }

    /// The storage plugin configuration
    let storageConfiguration: AWSS3StoragePluginConfiguration

    /// Instantiates an instance of the AWSS3StoragePlugin.
    public init(configuration
                    storageConfiguration: AWSS3StoragePluginConfiguration = AWSS3StoragePluginConfiguration()) {
        self.storageConfiguration = storageConfiguration
    }
}

extension AWSS3StoragePlugin: AmplifyVersionable { }
