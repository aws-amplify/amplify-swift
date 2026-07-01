//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// SDK-level metadata stamped on every enriched event.
public struct SDKMetadata: Sendable {
    /// SDK name (e.g., "amplify-swift").
    public let name: String

    /// SDK version string.
    public let version: String

    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}
