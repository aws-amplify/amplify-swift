//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.URL

extension PackageInfo {

    public struct Metadata: Codable {

        public struct Author: Codable {
            public let name: String
            public let email: String?
            public let description: String?
            public let organization: Organization?
            public let url: URL?

            public struct Organization: Codable {
                public let name: String
                public let email: String?
                public let description: String?
                public let url: URL?
            }
        }

        public let author: Author?
        public let description: String?
        public let licenseURL: URL?
        public let originalPublicationTime: String?
        public let readmeURL: URL?
        public let repositoryURLs: [URL]?
    }
}
