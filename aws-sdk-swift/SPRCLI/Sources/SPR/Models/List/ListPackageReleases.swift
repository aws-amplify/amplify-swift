//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.URL

public struct ListPackageReleases: Codable {

    public struct Release: Codable {

        public struct Problem: Codable {
            public let type: URL?
            public let title: String?
            public let status: Int?
            public let detail: String?
            public let instance: URL?
        }

        public let url: URL?
        public let problem: Problem?
    }

    public var releases: [String: Release]
}
