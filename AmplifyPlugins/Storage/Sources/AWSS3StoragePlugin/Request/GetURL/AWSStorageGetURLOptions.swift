//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
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
///         pluginOptions: AWSStorageGetURLOptions(
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

    /// The access method for the pre-signed URL. Defaults to `.get`.
    /// Use `.put` to generate a pre-signed URL for uploading.
    public var method: StorageAccessMethod = .get

    /// Creates options with all configurable parameters.
    ///
    /// - Parameters:
    ///   - validateObjectExistence: Whether to validate the object exists before generating the URL.
    ///   - method: The access method for the pre-signed URL (`.get` or `.put`).
    public init(
        validateObjectExistence: Bool = false,
        method: StorageAccessMethod = .get
    ) {
        self.validateObjectExistence = validateObjectExistence
        self.method = method
    }

    /// - Tag: AWSStorageGetURLOptions.init
    public init(validateObjectExistence: Bool) {
        self.validateObjectExistence = validateObjectExistence
        self.method = .get
    }
}
