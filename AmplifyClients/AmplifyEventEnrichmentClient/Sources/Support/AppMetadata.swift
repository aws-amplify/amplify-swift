//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Application-level metadata stamped on every enriched event.
public struct AppMetadata: Sendable {
    /// Application identifier used in the event envelope.
    public let appId: String

    /// Application package name (e.g., bundle identifier).
    public let packageName: String?

    /// Application version name (e.g., CFBundleShortVersionString).
    public let versionName: String?

    /// Application version code (e.g., CFBundleVersion).
    public let versionCode: String?

    /// Application display title.
    public let title: String?

    public init(
        appId: String,
        packageName: String? = nil,
        versionName: String? = nil,
        versionCode: String? = nil,
        title: String? = nil
    ) {
        self.appId = appId
        self.packageName = packageName
        self.versionName = versionName
        self.versionCode = versionCode
        self.title = title
    }
}
