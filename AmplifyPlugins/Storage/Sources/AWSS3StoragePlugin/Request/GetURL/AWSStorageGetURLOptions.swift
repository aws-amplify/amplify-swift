//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Provides options specific to the AWS S3 plugin implementation of the Storage category.
///
/// Usage example:
///
/// ```
/// // Because `validateObjectExistence` is set to true, the
/// // underlying plugin will throw and error if no S3 object
/// // can be resolved with the given key.
/// let url = try await Amplify.Storage.getURL(
///     key: "ExampleKey",
///     options: .init(
///         accessLevel: .private,
///         pluginOptions: S3GetUrlPluginOptions(
///             validateObjectExistence: true
///         )
///     )
/// )
/// ```
///
/// See: [StorageListRequestOptions.pluginOptions](x-source-tag://StorageListRequestOptions.pluginOptions)
///
/// - Tag: AWSStorageGetURLOptions
public struct AWSStorageGetURLOptions {

    /// When `validateObjectExistence` is set to `true`, the AWSS3StoragePlugin will ensure
    /// the S3 object represented by the given key exists **before** returning a pre-signed URL. If no
    /// such object exits at the time of the URL creation, an error is thrown.
    ///
    /// - Note: Setting this to `true` will result in a latency cost since confirming the existence of the
    ///         underlying S3 object will likely require a round-trip network call.
    ///
    /// - Tag: AWSStorageGetURLOptions.validateObjectExistence
    public var validateObjectExistence: Bool = false

    /// - Tag: AWSStorageGetURLOptions.init
    public init(validateObjectExistence: Bool) {
        self.validateObjectExistence = validateObjectExistence
    }
}
