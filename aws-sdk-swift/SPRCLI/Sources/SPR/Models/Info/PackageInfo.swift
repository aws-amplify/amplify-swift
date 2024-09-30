//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct PackageInfo: Codable {
    public let id: String
    public let version: String
    public let resources: [Resource]
    public let metadata: Metadata
    public let publishedAt: String?
}
