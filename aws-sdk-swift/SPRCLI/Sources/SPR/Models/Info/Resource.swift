//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct Resource: Codable {

    public struct Signing: Codable {
        public let signatureBase64Encoded: String
        public let signatureFormat: String
    }

    public let name: String
    public let type: String
    public let checksum: String
    public let signing: Signing?
}
