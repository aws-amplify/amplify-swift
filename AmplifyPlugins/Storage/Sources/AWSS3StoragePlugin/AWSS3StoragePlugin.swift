//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

/// The AWSS3StoragePlugin which conforms to the Amplify plugin protocols and implements the Storage
/// Plugin APIs for AWS S3.
///
/// - Tag: AWSS3StoragePlugin
final public class AWSS3StoragePlugin: StorageCategoryPlugin {

    /// An instance of the S3 storage service.
    var storageService: AWSS3StorageServiceBehavior!

    /// An instance of the authentication service.
    var authService: AWSAuthServiceBehavior!

    /// A queue that regulates the execution of operations.
    var queue: OperationQueue!

    /// Options object, including library specific configuration such as default access level.
    var options: AWSS3StoragePluginOptions!

    /// The unique key of the plugin within the storage category.
    ///
    /// - Tag: AWSS3StoragePlugin.key
    public var key: PluginKey {
        return PluginConstants.awsS3StoragePluginKey
    }

    /// The storage plugin configuration
    let storageConfiguration: AWSS3StoragePluginConfiguration

    /// See [HttpClientEngineProxy](x-source-tag://HttpClientEngineProxy)
    internal var httpClientEngineProxy: HttpClientEngineProxy?

    /// See [URLRequestDelegate](x-source-tag://URLRequestDelegate)
    internal weak var urlRequestDelegate: URLRequestDelegate?

    /// Instantiates an instance of the AWSS3StoragePlugin.
    ///
    /// - Tag: AWSS3StoragePlugin.init
    public init(configuration
                storageConfiguration: AWSS3StoragePluginConfiguration = AWSS3StoragePluginConfiguration(),
                options: AWSS3StoragePluginOptions? = nil) {
        self.storageConfiguration = storageConfiguration
    }
}

extension AWSS3StoragePlugin: AmplifyVersionable { }
