//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Configuration for the underlying `URLSession` used by the S3 storage service.
///
/// On iOS, tvOS, and watchOS the storage service uses a background `URLSession` identified by `sessionIdentifier`.
/// On macOS and visionOS a default session configuration is used instead.
///
/// - `sessionIdentifier`: The unique identifier for the background `URLSession`.
/// - `sharedContainerIdentifier`: An app group container identifier that lets extensions and the host app
///   share upload/download data. Maps to `URLSessionConfiguration.sharedContainerIdentifier`.
/// - `allowsCellularAccess`: Whether transfers are permitted over cellular networks.
/// - `timeoutIntervalForResource`: The maximum time a resource request is allowed to take.
struct StorageConfiguration {
    enum Defaults {
        static let sessionIdentifier = "com.amazon.aws.default.identifier"
        static let sharedContainerIdentifier = "com.amazon.aws.default.identifier-shared"
        static let allowsCellularAccess = true
        static let timeoutIntervalForResource = TimeInterval.minutes(50)
    }

    let sessionIdentifier: String
    let sharedContainerIdentifier: String?
    let allowsCellularAccess: Bool
    let timeoutIntervalForResource: TimeInterval

    init(
        sessionIdentifier: String = Defaults.sessionIdentifier,
        sharedContainerIdentifier: String = Defaults.sharedContainerIdentifier,
        allowsCellularAccess: Bool = Defaults.allowsCellularAccess,
        timeoutIntervalForResource: TimeInterval = Defaults.timeoutIntervalForResource
    ) {
        self.sessionIdentifier = sessionIdentifier
        self.sharedContainerIdentifier = sharedContainerIdentifier
        self.allowsCellularAccess = allowsCellularAccess
        self.timeoutIntervalForResource = timeoutIntervalForResource
    }

    init(forBucket bucket: String) {
        self.init(
            sessionIdentifier: "\(Defaults.sessionIdentifier).\(bucket)"
        )
    }
}
