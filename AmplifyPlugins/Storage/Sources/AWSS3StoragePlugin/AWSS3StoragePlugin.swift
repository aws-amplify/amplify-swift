//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyConfiguration) import Amplify
import Foundation
import AWSPluginsCore
import InternalAmplifyCredentials

/// The AWSS3StoragePlugin which conforms to the Amplify plugin protocols and implements the Storage
/// Plugin APIs for AWS S3.
///
/// - Tag: AWSS3StoragePlugin
final public class AWSS3StoragePlugin: StorageCategoryPlugin {

    /// The default S3 storage service.
    var defaultStorageService: AWSS3StorageServiceBehavior! {
        guard let defaultBucket else {
            return nil
        }
        return storageServicesByBucket[defaultBucket.bucketInfo.bucketName]
    }

    /// The default bucket
    var defaultBucket: ResolvedStorageBucket!

    /// A dictionary of S3 storage service instances grouped by a specific bucket
    var storageServicesByBucket: AtomicDictionary<String, AWSS3StorageServiceBehavior> = [:]

    /// A dictionary of additional Outputs-based buckets, grouped by their names
    var additionalBucketsByName: [String: AmplifyOutputsData.Storage.Bucket]?

    /// An instance of the authentication service.
    var authService: AWSAuthCredentialsProviderBehavior!

    /// A queue that regulates the execution of operations.
    var queue: OperationQueue!

    /// The default access level used for API calls.
    @available(*, deprecated, message: "Use `path` in Storage API instead of `Options`")
    var defaultAccessLevel: StorageAccessLevel!

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
                storageConfiguration: AWSS3StoragePluginConfiguration = AWSS3StoragePluginConfiguration()) {
        self.storageConfiguration = storageConfiguration
    }
}

extension AWSS3StoragePlugin: AmplifyVersionable { }
