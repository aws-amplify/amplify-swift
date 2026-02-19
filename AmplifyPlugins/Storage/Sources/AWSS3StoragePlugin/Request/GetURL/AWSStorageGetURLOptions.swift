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

    /// The HTTP method for the pre-signed URL.
    /// Use `.put` to generate an upload URL, `.get` (default) for a download URL.
    public enum HTTPMethod: String {
        case get = "GET"
        case put = "PUT"
    }

    /// When `validateObjectExistence` is set to `true`, the AWSS3StoragePlugin will ensure
    /// the S3 object represented by the given key exists **before** returning a pre-signed URL. If no
    /// such object exits at the time of the URL creation, an error is thrown.
    ///
    /// - Note: Setting this to `true` will result in a latency cost since confirming the existence of the
    ///         underlying S3 object will likely require a round-trip network call.
    ///
    /// - Tag: AWSStorageGetURLOptions.validateObjectExistence
    public var validateObjectExistence: Bool = false

    /// The HTTP method for the pre-signed URL. Defaults to `.get`.
    public var method: HTTPMethod = .get

    /// The content type for PUT pre-signed URLs. Ignored for GET URLs.
    public var contentType: String?

    /// Creates options with all configurable parameters.
    ///
    /// - Parameters:
    ///   - validateObjectExistence: Whether to validate the object exists before generating the URL.
    ///   - method: The HTTP method for the pre-signed URL (`.get` or `.put`).
    ///   - contentType: The content type for PUT pre-signed URLs. Ignored for GET URLs.
    public init(
        validateObjectExistence: Bool = false,
        method: HTTPMethod = .get,
        contentType: String? = nil
    ) {
        self.validateObjectExistence = validateObjectExistence
        self.method = method
        self.contentType = contentType
    }

    /// - Tag: AWSStorageGetURLOptions.init
    public init(validateObjectExistence: Bool) {
        self.validateObjectExistence = validateObjectExistence
        self.method = .get
        self.contentType = nil
    }
}
